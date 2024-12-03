const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mvzr_dep = b.dependency("mvzr", .{
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addStaticLibrary(.{
        .name = "aoc",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);
    const run_all_step = b.step("run", "Run all days");

    for (1..4) |n| {
        const exe = b.addExecutable(.{
            .name = b.fmt("aoc_{}", .{n}),
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        const day_mod = b.addSharedLibrary(.{
            .name = "day",
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path(b.fmt("src/2024/day{}.zig", .{n})),
        });
        day_mod.root_module.addImport("mvzr", mvzr_dep.module("mvzr"));
        exe.linkLibrary(lib);
        exe.linkLibrary(day_mod);
        exe.root_module.addImport("day", &day_mod.root_module);
        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        const run_step = b.step(b.fmt("run_{}", .{n}), b.fmt("Run the day {}", .{n}));
        run_step.dependOn(&run_cmd.step);
        run_all_step.dependOn(run_step);
    }

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
