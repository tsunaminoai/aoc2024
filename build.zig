const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const test_step = b.step("test", "Run unit tests");

    const mvzr_dep = b.dependency("mvzr", .{
        .target = target,
        .optimize = optimize,
    });

    const root_mod = b.addModule("root", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "aoc",
        .root_module = root_mod,
        .linkage = .static,
    });

    b.installArtifact(lib);
    const run_all_step = b.step("run", "Run all days");

    for (1..26) |n| {
        const day_file = b.fmt("src/2024/day{}.zig", .{n});
        std.fs.cwd().access(day_file, .{}) catch {
            // std.log.info("Skipping: {s} (not found)", .{day_file});
            continue;
        };
        const day_mod = b.addModule(b.fmt("day{}", .{n}), .{
            .root_source_file = b.path(day_file),
            .target = target,
            .optimize = optimize,
        });
        day_mod.addImport("mvzr", mvzr_dep.module("mvzr"));
        const exe = b.addExecutable(.{
            .name = b.fmt("aoc_{}", .{n}),
            .root_module = day_mod,
        });
        exe.linkLibrary(lib);
        exe.root_module.addImport("day", day_mod);
        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        const run_step = b.step(b.fmt("run_{}", .{n}), b.fmt("Run the day {}", .{n}));
        run_step.dependOn(&run_cmd.step);
        run_all_step.dependOn(run_step);

        const day_tests = b.addTest(.{
            .root_module = day_mod,
        });

        const run_day_tests = b.addRunArtifact(day_tests);

        test_step.dependOn(&run_day_tests.step);
    }

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_module = root_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_module = b.addModule("exe_test", .{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.

    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
