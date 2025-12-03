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
    const result: i64 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var b = try Bank.init(allocator, line);
        defer b.deinit();

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

    pub fn getMax(self: Bank) !i64 {
        var ret: i64 = 0;
        var b = try self.batteries.clone(self.alloc);
        defer b.deinit(self.alloc);

        for (b.items[1..b.items.len], 1..) |j, i| {
            if (j.joltage < b.items[i - 1].joltage) _ = b.orderedRemove(i);
        }
        std.debug.print("{}\n", .{b});
        ret += b.items[0].joltage * 10;
        ret += b.items[1].joltage;
        return ret;
    }
};
const test_input =
    \\987654321111111
    \\811111111111119
    \\234234234234278
    \\818181911112111
;

test "joltage for bank" {
    var b = try Bank.init(tst.allocator, "12345");
    defer b.deinit();
    b.batteries.items[1].enabled = true;
    b.batteries.items[3].enabled = true;
    try tst.expectEqual(24, try b.joltage());
    try tst.expectEqual(45, try b.getMax());
}

test "part 1" {
    const example = test_input;

    const result = try part1(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 0), result);
}

test "part 2" {
    const example = test_input;

    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 0), result);
}
