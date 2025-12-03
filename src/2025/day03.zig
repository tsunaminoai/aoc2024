const std = @import("std");
const util = @import("util");
const mvzr = @import("mvzr");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;

// Automatically embedded at compile time
pub const data = @embedFile("data/day03.txt");
pub const DayNumber = 3;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var result: i64 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var b = try Bank.init(allocator, line);
        defer b.deinit();
        result += try b.getMaxJoltage();
        // std.debug.print("{any}\n", .{b});
    }

    return result;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    const result: i64 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        _ = line;
        // Your solution here
    }

    return result;
}

const Battery = struct {
    joltage: i64 = 0,
    enabled: bool = false,
    pub fn isLessThan(_: @TypeOf(.{}), self: Battery, other: Battery) bool {
        return self.joltage < other.joltage;
    }
    pub fn format(
        self: Battery,
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        if (self.enabled)
            try writer.print("\x1B[1m{c}\x1B[0m", .{@as(u8, @intCast(self.joltage)) + '0'})
        else
            try writer.print("\x1B[2m{c}\x1B[0m", .{@as(u8, @intCast(self.joltage)) + '0'});
    }
};
const Bank = struct {
    batteries: Array(Battery) = .{},
    alloc: Allocator,
    pub fn init(allocator: Allocator, str: []const u8) !Bank {
        var b = Bank{
            .alloc = allocator,
        };
        for (str[0..]) |c| {
            try b.batteries.append(allocator, .{ .joltage = @intCast(c - '0') });
        }
        return b;
    }
    pub fn deinit(self: *Bank) void {
        self.batteries.deinit(self.alloc);
    }
    /// the joltage that the bank produces is equal to the number formed by the digits on the batteries you've turned on.
    pub fn joltage(self: Bank) !i64 {
        var ret: Array(u8) = .{};
        defer ret.deinit(self.alloc);
        for (self.batteries.items) |b| {
            if (b.enabled) try ret.append(self.alloc, @intCast(b.joltage + '0'));
        }
        return try std.fmt.parseInt(i64, ret.items, 10);
    }

    /// Finds the largest possible joltage for the bank
    /// Slides from the left and right looking for the largest number
    /// When both sides are defined, the answer is produced.
    pub fn getMaxJoltage(self: Bank) !i64 {
        var ret: i64 = 0;
        var left: i64 = 0;
        var right: i64 = 0;
        var idx: usize = 0;
        var pos: usize = 0;
        var posr: usize = 0;
        while (idx < self.batteries.items.len - 1) : (idx += 1) {
            if (self.batteries.items[idx].joltage > left) {
                left = self.batteries.items[idx].joltage;
                pos = idx;
            }
        }
        self.batteries.items[pos].enabled = true;
        // std.debug.print("pos: {} jolt: {}\n", .{ pos, self.batteries.items[pos].joltage });
        idx = self.batteries.items.len - 1;
        while (idx > 0) : (idx -= 1) {
            if (self.batteries.items[idx].joltage >= right and idx > pos) {
                right = self.batteries.items[idx].joltage;
                posr = idx;
            }
        }
        self.batteries.items[posr].enabled = true;

        ret = left * 10 + right;

        return ret;
    }
    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        for (self.batteries.items) |b|
            try b.format(writer);
    }
};
const test_input =
    \\987654321111111
    \\811111111111119
    \\234234234234278
    \\818181911112111
;

pub fn testJoltage(expected: i64, str: []const u8) !void {
    var b = try Bank.init(tst.allocator, str);
    defer b.deinit();
    try tst.expectEqual(expected, try b.getMaxJoltage());
    std.debug.print("{f}\n", .{b});
}

test "joltage for bank" {
    var b = try Bank.init(tst.allocator, "12345");
    defer b.deinit();
    b.batteries.items[1].enabled = true;
    b.batteries.items[3].enabled = true;
    try tst.expectEqual(24, try b.joltage());

    try testJoltage(98, "987654321111111");
    try testJoltage(89, "811111111111119");
    try testJoltage(78, "234234234234278");
    try testJoltage(92, "818181911112111");
}

test "part 1" {
    const example = test_input;

    const result = try part1(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 357), result);
}

test "part 2" {
    const example = test_input;

    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 0), result);
}
