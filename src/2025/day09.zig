const std = @import("std");
const util = @import("util");
const mvzr = @import("mvzr");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;

// Automatically embedded at compile time
pub const data = @embedFile("data/day09.txt");
pub const DayNumber = 9;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator; // autofix
    const result: i64 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        _ = line; // autofix
        // Your solution here
    }

    return result;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator; // autofix
    const result: i64 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        _ = line; // autofix
        // Your solution here
    }

    return result;
}

const Floor = struct {
    coords: Array(util.grid.Coord),
    alloc: Allocator,

    pub fn init(alloc: Allocator) Floor {
        return .{
            .coords = .{},
            .alloc = alloc,
        };
    }
    pub fn deinit(self: *Floor) void {
        self.coords.deinit(self.alloc);
    }

    pub fn addCoordStr(self: *Floor, str: []const u8) !void {
        const comma = std.mem.indexOfScalar(u8, str, ',') orelse return error.InvalidCoord;
        const x = try std.fmt.parseInt(usize, str[0..comma], 10);
        const y = try std.fmt.parseInt(usize, str[comma + 1 ..], 10);
        try self.coords.append(self.alloc, .{ .x = x, .y = y });
    }
};

const test_input =
    \\7,1
    \\11,1
    \\11,7
    \\9,7
    \\9,5
    \\2,5
    \\2,3
    \\7,3
;

test "floor" {
    var f = Floor.init(tst.allocator);
    defer f.deinit();

    var iter = std.mem.splitScalar(u8, test_input, '\n');
    while (iter.next()) |line| {
        try f.addCoordStr(line);
    }

    try tst.expectEqual(8, f.coords.items.len);
}

test "part 1" {
    const example = test_input;

    const result = try part1(std.testing.allocator, example);
    _ = result; // autofix
    // try std.testing.expectEqual(@as(i64, 50), result);
}

test "part 2" {
    const example = test_input;

    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 0), result);
}
