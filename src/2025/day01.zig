const std = @import("std");
const util = @import("util");
const mvzr = @import("mvzr");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;
pub const DayNumber = 1;

// Automatically embedded at compile time
pub const data = @embedFile("data/day01.txt");

/// The safe has a dial with only an arrow on it;
/// around the dial are the numbers 0 through 99 in order.
///  As you turn the dial, it makes a small click noise as
///  it reaches each number.
// left - / right +, % 100
// starts at 50
// The actual password is the number of times
// the dial is left pointing at 0 after any rotation
// in the sequence.

pub const Safe = struct {
    current: i64 = 50,
    zero_landings: i64 = 0,
    zero_crossings: i64 = 0,

    pub fn rotate(self: *Safe, dir: u8, amount: i64) !void {
        // std.debug.print("Moving {c} by {}\n", .{ dir, amount });
        var amt = @mod(amount, 100);
        self.zero_crossings += @divFloor(amount, 100);

        if (dir == 'L') amt *= -1;

        if (self.current + amt >= 100 or (self.current > 0 and self.current + amt <= 0)) {
            self.zero_crossings += 1;
        }
        if (self.current == 0) self.zero_landings += 1;
        self.current = @mod(self.current + amt, 100);
    }
};

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    var safe = Safe{};

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try safe.rotate(line[0], try std.fmt.parseInt(i64, line[1..], 10));
    }

    return safe.zero_landings;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    var safe = Safe{};

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try safe.rotate(line[0], try std.fmt.parseInt(i64, line[1..], 10));
        // std.debug.print("{any}\n", .{safe});
    }

    return safe.zero_crossings;
}

test "part 1 example" {
    const example =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;
    const result = try part1(std.testing.allocator, example);
    try std.testing.expectEqual(3, result);
}

test "part 2 example" {
    const example =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
        \\L1000
    ;
    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(16, result);
}
