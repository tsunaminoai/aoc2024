const std = @import("std");
const util = @import("util");
const mvzr = @import("mvzr");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;

// Automatically embedded at compile time
pub const data = @embedFile("data/day04.txt");
pub const DayNumber = 4;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var result: i64 = 0;

    var grid = try PaperGrid.init(allocator, input);
    defer grid.deinit();

    for (0..grid.height) |h| {
        for (0..grid.width) |w| {
            if (grid.canRollBeMoved(h, w)) result += 1;
        }
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
const Roll = u8;
const PaperGrid = struct {
    width: usize = 0,
    height: usize = 0,

    rolls: Array(Roll) = .{},
    alloc: Allocator,

    pub fn init(alloc: Allocator, str: []const u8) !PaperGrid {
        return .{
            .alloc = alloc,
            .width = std.mem.indexOfScalar(u8, str, '\n') orelse return error.InvalidInput,
            .height = std.mem.count(u8, str, "\n"),
            .rolls = blk: {
                var r = Array(Roll){};
                var lines = std.mem.tokenizeScalar(u8, str, '\n');
                while (lines.next()) |line| {
                    try r.appendSlice(alloc, line);
                }
                break :blk r;
            },
        };
    }
    pub fn deinit(self: *PaperGrid) void {
        self.rolls.deinit(self.alloc);
    }

    fn neighbors(self: PaperGrid, y: usize, x: usize) [8]?usize {
        var n: [8]?usize = undefined;
        const yi: isize = @intCast(y);
        const xi: isize = @intCast(x);
        const directions = [_]struct { isize, isize }{
            .{ -1, -1 }, .{ -1, 0 }, .{ -1, 1 },
            .{ 0, -1 }, .{ 0, 1 }, //.{ 0, 0 }
            .{ 1, -1 }, .{ 1, 0 },
            .{ 1, 1 },
        };
        for (directions, 0..) |d, i| {
            n[i] = if (yi + d[0] < 0 or
                yi + d[0] >= @as(isize, @intCast(self.height)) or
                xi + d[1] < 0 or
                xi + d[1] >= @as(isize, @intCast(self.width)))
                null
            else
                @intCast((yi + d[0]) * @as(isize, @intCast(self.width)) + (xi + d[1]));
        }
        return n;
    }
    pub fn canRollBeMoved(self: PaperGrid, y: usize, x: usize) bool {
        const idx = (y * self.width) + x;
        if (idx >= self.rolls.items.len) return false;
        // std.debug.print("{c}", .{self.rolls.items[idx]});
        if (self.rolls.items[idx] != '@') return false;
        const n = self.neighbors(y, x);
        var count: usize = 0;
        for (n) |ridx| {
            if (ridx) |r| {
                if (self.rolls.items[r] == '@') count += 1;
            }
        }

        // std.debug.print("{any}\n", .{n});
        return count < 4;
    }
    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        for (self.rolls.items, 0..) |r, i| {
            switch (r) {
                '.' => try writer.print("_", .{}),
                '@' => try writer.print("#", .{}),
                else => {},
            }
            if (@mod(i, self.width - 1) == 0 and i != 0) {
                try writer.print("\n", .{});
                try writer.flush();
            }
        }
    }
};

/// Where @ is a roll of paper
/// The forklifts can only access a roll of paper if there are fewer than four rolls of paper in the eight adjacent positions.
const test_input =
    \\..@@.@@@@.
    \\@@@.@.@.@@
    \\@@@@@.@.@@
    \\@.@@@@..@.
    \\@@.@@@@.@@
    \\.@@@@@@@.@
    \\.@.@.@.@@@
    \\@.@@@.@@@@
    \\.@@@@@@@@.
    \\@.@.@@@.@.
;

test "neighbors" {
    var g = try PaperGrid.init(tst.allocator, test_input);
    defer g.deinit();
    // std.debug.print("\n{f}", .{g});
    // std.debug.print("{any}\n", .{g.neighbors(0, 0)});
    try tst.expect(std.mem.count(?usize, &g.neighbors(0, 0), &.{null}) == 5);
}
test "Paper Grid" {
    var g = try PaperGrid.init(tst.allocator, test_input);
    defer g.deinit();
    try tst.expect(!g.canRollBeMoved(0, 0)); // nothing there
    try tst.expect(g.canRollBeMoved(0, 3)); // can be moved
    try tst.expect(!g.canRollBeMoved(1, 1)); // cant be moved

}
test "part 1" {
    const example = test_input;

    const result = try part1(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 13), result);
}

test "part 2" {
    const example = test_input;

    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 0), result);
}
