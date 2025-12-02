const std = @import("std");
const util = @import("util");
const mvzr = @import("mvzr");
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
    current: usize = 50,
    zero_landings: i64 = 0,

    pub fn rotate(self: *Safe, dir: u8, amount: usize) !void {
        // std.debug.print("Moving {c} by {}\n", .{ dir, amount });
        const amt = @mod(amount, 100);
        switch (dir) {
            'L' => {
                if (amt > self.current)
                    self.current = 100 - (amt - self.current)
                else
                    self.current -= amt;
            },
            'R' => {
                self.current += amt;
                if (self.current >= 100) self.current -= 100;
            },
            else => return error.InvalidRotation,
        }
        if (self.current == 0) self.zero_landings += 1;
    }
};

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    var safe = Safe{};

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        // std.debug.print("{any}\n", .{safe});
        try safe.rotate(line[0], try std.fmt.parseInt(usize, line[1..], 10));
        // Your solution here
    }

    return safe.zero_landings;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    _ = input;
    return 0;
}

test "part 1 example" {
    const example =
        \\L968
        \\L930
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
    try std.testing.expectEqual(@as(i64, 3), result);
}

test "part 2 example" {
    const example =
        \\example input
    ;
    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 0), result);
}
