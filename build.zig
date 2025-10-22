const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add year option (defaults to current year)
    const year_option = b.option(
        []const u8,
        "year",
        "Advent of Code year to build (default: 2024)",
    ) orelse "2024";

    const mvzr = b.dependency("mvzr", .{});

    // Create shared utilities module
    const util_mod = b.addModule("util", .{
        .root_source_file = b.path("src/util/aoc.zig"),
        .target = target,
        .optimize = optimize,
    });
    util_mod.addImport("mvzr", mvzr.module("mvzr"));

    // Add utility sub-modules as anonymous imports
    util_mod.addAnonymousImport("grid", .{
        .root_source_file = b.path("src/util/grid.zig"),
    });
    util_mod.addAnonymousImport("parse", .{
        .root_source_file = b.path("src/util/parse.zig"),
    });
    util_mod.addAnonymousImport("math", .{
        .root_source_file = b.path("src/util/math.zig"),
    });

    // Build all days step
    const all_step = b.step("all", "Build all available days");
    const all_tests_step = b.step("test", "Run all tests");

    // Track if we built anything
    var built_any = false;

    // Generate targets for each day
    for (1..26) |day| {
        const day_str = b.fmt("day{}", .{day});
        const src_path = b.fmt("src/{s}/{s}.zig", .{ year_option, day_str });

        // Check if source file exists
        const file_exists = checkFileExists(b, src_path);
        if (!file_exists) {
            continue; // Skip this day if file doesn't exist
        }

        built_any = true;

        // Create executable for this day
        const exe = b.addExecutable(.{
            .name = day_str,
            .root_module = b.createModule(.{
                .root_source_file = b.path(src_path),
                .target = target,
                .optimize = optimize,
            }),
        });

        // Add utilities module
        exe.root_module.addImport("util", util_mod);
        exe.root_module.addImport("mvzr", mvzr.module("mvzr"));

        // Create install step
        const install = b.addInstallArtifact(exe, .{});

        // Add to "build all" step
        all_step.dependOn(&install.step);

        // Create run step for this day
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&install.step);

        // Allow passing arguments
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step(day_str, b.fmt("Run {s}", .{day_str}));
        run_step.dependOn(&run_cmd.step);

        // Create benchmark step for this day
        const bench_cmd = b.addRunArtifact(exe);
        bench_cmd.step.dependOn(&install.step);
        bench_cmd.addArg("--bench");

        const bench_step = b.step(
            b.fmt("bench_{s}", .{day_str}),
            b.fmt("Benchmark {s}", .{day_str}),
        );
        bench_step.dependOn(&bench_cmd.step);

        // Create test step for this day
        const day_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(src_path),
                .target = target,
                .optimize = optimize,
            }),
        });
        day_tests.root_module.addImport("util", util_mod);
        day_tests.root_module.addImport("mvzr", mvzr.module("mvzr"));

        const run_tests = b.addRunArtifact(day_tests);
        const test_step = b.step(
            b.fmt("test_{s}", .{day_str}),
            b.fmt("Test {s}", .{day_str}),
        );
        test_step.dependOn(&run_tests.step);

        // Add to global test step
        all_tests_step.dependOn(&run_tests.step);
    }

    // Print info about what we're building
    if (!built_any) {
        std.debug.print("No solution files found in src/{s}/\n", .{year_option});
    }
}

/// Check if a file exists at build time
inline fn checkFileExists(_: *std.Build, path: []const u8) bool {
    const cwd = std.fs.cwd();
    const file = cwd.openFile(path, .{}) catch return false;
    file.close();
    return true;
}
