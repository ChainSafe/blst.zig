const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const portable = b.option(bool, "portable", "turn on portable mode") orelse false;

    const upstream = b.dependency("blst", .{});

    var c_flags = std.ArrayList([]const u8).init(b.allocator);
    defer c_flags.deinit();

    try c_flags.append("-fno-builtin");
    try c_flags.append("-Wno-unused-function");
    try c_flags.append("-Wno-unused-command-line-argument");

    if (target.result.cpu.arch == .x86_64) {
        try c_flags.append("-mno-avx"); // avoid costly transitions
    }

    const lib = b.addLibrary(.{
        .name = "blst",
        .root_module = b.createModule(
            .{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            },
        ),
    });

    if (portable) {
        lib.root_module.addCMacro("__BLST_PORTABLE__", "");
    } else {
        if (std.Target.x86.featureSetHas(target.result.cpu.features, .adx)) {
            lib.root_module.addCMacro("__ADX__", "");
        }
    }

    if (target.result.cpu.arch == .aarch64) lib.root_module.addCMacro("__ARM_FEATURE_CRYPTO", "1");

    if (target.result.cpu.arch != .x86_64 and
        target.result.cpu.arch != .aarch64)
    {
        lib.root_module.addCMacro("__BLST_NO_ASM__", "");
    }
    lib.installHeader(upstream.path("bindings/blst.h"), "blst.h");
    lib.installHeader(upstream.path("bindings/blst_aux.h"), "blst_aux.h");

    lib.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &.{
            "src/server.c",
            "build/assembly.S",
        },
        .flags = c_flags.items,
    });

    b.installArtifact(lib);
}
