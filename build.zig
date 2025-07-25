const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ztep = b.addModule("ztep", .{
        .root_source_file = b.path("src/ztep.zig"),
        .target = target,
        .optimize = optimize,
    });

    // run: build test --summary new
    const tests = b.addTest(.{ .root_module = ztep });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run all tests in all modes.");
    test_step.dependOn(&run_tests.step);

    b.default_step.dependOn(test_step);
}
