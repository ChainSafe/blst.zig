[blst](https://github.com/supranational/blst/) packaged for [Zig](https://ziglang.org/)

# Usage

```sh
zig fetch --save git+https://github.com/ChainSafe/blst.zig.git
```

```zig
const blst_dep = b.dependency("blst", .{
    .target = target,
    .optimize = optimize,
});

your_exe.linkLibrary(blst_dep.artifact("blst"));
```
