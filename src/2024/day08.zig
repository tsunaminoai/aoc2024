const std = @import("std");
const lib = @import("lib.zig");
const Error = lib.Error;

pub const DayNumber = 0;
pub const data = @embedFile("data/8.txt");

pub const Answer1 = 0;
pub const Answer2 = 0;

pub fn part1(_: std.mem.Allocator, in: []const u8) Error!i64 {
    const ret: i64 = 0;
    _ = in;
    return ret;
}
pub fn part2(_: std.mem.Allocator, in: []const u8) Error!i64 {
    const ret: i64 = 0;
    _ = in;
    return ret;
}
const test_input =
    \\
;

test {
    try std.testing.expectEqual(0, part1(test_input));
    try std.testing.expectEqual(0, part2(test_input));
}
