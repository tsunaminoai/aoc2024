const std = @import("std");
const util = @import("util");
const mvzr = @import("mvzr");
pub const DayNumber = 1;

// Automatically embedded at compile time
pub const data = @embedFile("data/day01.txt");

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    const result: i64 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        _ = line;
        // Your solution here
    }

    return result;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    _ = input;
    return 0;
}

test "part 1 example" {
    const example =
        \\example input
    ;
    const result = try part1(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 42), result);
}

test "part 2 example" {
    const example =
        \\example input
    ;
    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 123), result);
}
