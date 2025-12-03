const std = @import("std");
const util = @import("util");
const day = @import("day");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip(); // Skip program name

    const is_bench = if (args.next()) |arg|
        std.mem.eql(u8, arg, "--bench")
    else
        false;

    // Setup buffered stdout
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};

    // Run the appropriate day
    try runDay(allocator, stdout, is_bench);
    try stdout.flush();
}

fn runDay(
    allocator: std.mem.Allocator,
    stdout: *std.Io.Writer,
    is_bench: bool,
) !void {
    try runDayImpl(day, allocator, stdout, day.DayNumber, is_bench);
}

fn runDayImpl(
    comptime day_module: type,
    allocator: std.mem.Allocator,
    stdout: *std.Io.Writer,
    daynum: u8,
    is_bench: bool,
) !void {
    if (is_bench) {
        try benchmarkDay(day_module, allocator, stdout, daynum);
    } else {
        try executeDay(day_module, allocator, stdout, daynum);
    }
}

fn executeDay(
    comptime day_module: type,
    allocator: std.mem.Allocator,
    stdout: *std.Io.Writer,
    daynum: u8,
) !void {
    const input = day_module.data;

    // Time part 1
    const part1_result = try util.timed(i64, day_module.part1, .{ allocator, input });
    const part1_time = util.formatTime(part1_result.time_ns);

    // Time part 2
    const part2_result = try util.timed(i64, day_module.part2, .{ allocator, input });
    const part2_time = util.formatTime(part2_result.time_ns);

    // Calculate total
    const total_ns = part1_result.time_ns + part2_result.time_ns;
    const total_time = util.formatTime(total_ns);

    // Print results
    try stdout.print("Day {d:>2}:\n", .{daynum});
    try stdout.print("  Part 1: {d:>15} (", .{part1_result.result});
    try part1_time.format(stdout);
    try stdout.print(")\n", .{});

    try stdout.print("  Part 2: {d:>15} (", .{part2_result.result});
    try part2_time.format(stdout);
    try stdout.print(")\n", .{});

    try stdout.print("  Total:  {s:>15} (", .{""});
    try total_time.format(stdout);
    try stdout.print(")\n", .{});
}

fn benchmarkDay(
    comptime day_module: type,
    allocator: std.mem.Allocator,
    stdout: *std.Io.Writer,
    daynum: u8,
) !void {
    const input = day_module.data;
    const iterations: usize = 100;

    try stdout.print("Day {d:>2} Benchmark ({d} iterations):\n", .{ daynum, iterations });

    // Benchmark part 1
    const bench1 = try util.benchmark(i64, day_module.part1, .{ allocator, input }, iterations);
    const avg1 = util.formatTime(bench1.avg_ns);
    const min1 = util.formatTime(bench1.min_ns);
    const max1 = util.formatTime(bench1.max_ns);

    try stdout.print("  Part 1: {d:>15}\n", .{bench1.result});
    try stdout.print("    Avg: ", .{});
    try avg1.format(stdout);
    try stdout.print("  Min: ", .{});
    try min1.format(stdout);
    try stdout.print("  Max: ", .{});
    try max1.format(stdout);
    try stdout.print("\n", .{});

    // Benchmark part 2
    const bench2 = try util.benchmark(i64, day_module.part2, .{ allocator, input }, iterations);
    const avg2 = util.formatTime(bench2.avg_ns);
    const min2 = util.formatTime(bench2.min_ns);
    const max2 = util.formatTime(bench2.max_ns);

    try stdout.print("  Part 2: {d:>15}\n", .{bench2.result});
    try stdout.print("    Avg: ", .{});
    try avg2.format(stdout);
    try stdout.print("  Min: ", .{});
    try min2.format(stdout);
    try stdout.print("  Max: ", .{});
    try max2.format(stdout);
    try stdout.print("\n", .{});
}
