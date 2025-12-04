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

    result = try grid.process();

    // std.debug.print("\n\n{f}\n", .{grid});

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
const Cell = struct {
    kind: Kind,
    remove: bool,

    const Kind = enum(u8) {
        empty = '.',
        roll = '@',
    };

    pub fn init(char: u8) !Cell {
        return .{
            .kind = @enumFromInt(char),
            .remove = false,
        };
    }

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        switch (self.kind) {
            .empty => try writer.writeAll("."),
            .roll => if (self.remove)
                try writer.writeAll("x")
            else
                try writer.writeAll("@"),
        }
        try writer.flush();
    }
};
const PaperGrid = struct {
    width: usize = 0,
    height: usize = 0,

    cells: Array(Cell) = .{},
    alloc: Allocator,

    pub fn remove(self: *PaperGrid, y: usize, x: usize) void {
        self.cells.items[self.idx(y, x)].remove = true;
    }

    fn idx(self: PaperGrid, y: usize, x: usize) usize {
        return (y * self.width) + x;
    }

    pub fn init(alloc: Allocator, str: []const u8) !PaperGrid {
        return .{
            .alloc = alloc,
            .width = std.mem.indexOfScalar(u8, str, '\n') orelse return error.InvalidInput,
            .height = std.mem.count(u8, str, "\n") + 1,
            .cells = blk: {
                var c = Array(Cell){};
                var lines = std.mem.tokenizeScalar(u8, str, '\n');
                while (lines.next()) |line| {
                    for (line[0..line.len]) |ch| {
                        try c.append(alloc, try Cell.init(ch));
                    }
                }
                break :blk c;
            },
        };
    }
    pub fn deinit(self: *PaperGrid) void {
        self.cells.deinit(self.alloc);
    }
    pub fn process(self: *PaperGrid) !i64 {
        var ret: i64 = 0;
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                if (self.canRollBeMoved(y, x)) {
                    self.remove(y, x);
                    ret += 1;
                }
            }
        }
        return ret;
    }

    fn neighbors(self: PaperGrid, y: usize, x: usize) [8]?usize {
        var n: [8]?usize = .{null} ** 8;
        const directions = [_]struct { i32, i32 }{
            // zig fmt: off
            .{ -1, -1 }, .{ -1, 0 }, .{ -1, 1 },
            .{  0, -1 },             .{  0, 1 },
            .{  1, -1 }, .{  1, 0 }, .{  1, 1 },
            // zig fmt: on
    };

    for (directions, 0..) |d, i| {
        const ny = @as(i32, @intCast(y)) + d[0];
        const nx = @as(i32, @intCast(x)) + d[1];
        if (ny < 0 or nx < 0) continue;
        const uy: usize = @intCast(ny);
        const ux: usize = @intCast(nx);
        if (uy >= self.height or ux >= self.width) continue;
        n[i] = self.idx(uy, ux);
    }
    return n;
}

    pub fn canRollBeMoved(self: PaperGrid, y: usize, x: usize) bool {
        if (self.idx(y, x) >= self.cells.items.len) return false;
        // std.debug.print("{c}", .{self.rolls.items[idx]});
        if (self.cells.items[self.idx(y, x)].kind != .roll) return false;
        const n = self.neighbors(y, x);
        var count: usize = 0;
        for (n) |cidx| {
            if (cidx) |r| {
                if (r >= self.cells.items.len) continue;
                const cell = self.cells.items[r];
                if (cell.kind == .roll) {
                    count += 1;
                }
            }
        }

        return count < 4;
    }
    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        for (0..self.cells.items.len ) |i| {
            const c = self.cells.items[i];
            try c.format(writer);
            try writer.flush();
            if (@mod(i + 1, self.width) == 0 and i < self.cells.items.len-1) {
                try writer.writeAll("\n");
            }
            try writer.flush();
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

const expected_removal =
    \\..xx.xx@x.
    \\x@@.@.@.@@
    \\@@@@@.x.@@
    \\@.@@@@..@.
    \\x@.@@@@.@x
    \\.@@@@@@@.@
    \\.@.@.@.@@@
    \\x.@@@.@@@@
    \\.@@@@@@@@.
    \\x.x.@@@.x.
;
test "neighbors" {
    var g = try PaperGrid.init(tst.allocator, test_input);
    defer g.deinit();
    // std.debug.print("\n{f}", .{g});
    // std.debug.print("{any}\n", .{g.neighbors(0, 0)});
    try tst.expectEqual(5, std.mem.count(?usize, &g.neighbors(0, 0), &.{null}));
    try tst.expectEqual(3, std.mem.count(?usize, &g.neighbors(9, 1), &.{null}));
}
test "Paper Grid" {
    var g = try PaperGrid.init(tst.allocator, test_input);
    defer g.deinit();
    try tst.expectEqual(10, g.width);
    try tst.expect(!g.canRollBeMoved(0, 0)); // nothing there
    try tst.expect(g.canRollBeMoved(0, 3)); // can be moved
    try tst.expect(!g.canRollBeMoved(1, 1)); // cant be moved

    _ = try g.process();

    const str = try std.fmt.allocPrint(tst.allocator, "{f}", .{g});
    defer tst.allocator.free(str);

    try tst.expectEqualStrings(expected_removal, str);
}
test "part 1" {
    const example = test_input;

    const result = try part1(std.testing.allocator, example);

    try std.testing.expectEqual(@as(i64, 13), result);
}

test "part 2" {
    const example = test_input;
    _ = example; // autofix

    // const result = try part2(std.testing.allocator, example);
    // try std.testing.expectEqual(@as(i64, 0), result);
}
