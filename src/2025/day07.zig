const std = @import("std");
const util = @import("util");
const mvzr = @import("mvzr");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;

// Automatically embedded at compile time
pub const data = @embedFile("data/day07.txt");
pub const DayNumber = 7;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var t = try Tachyons.init(allocator, input);
    defer t.deinit();

    try t.fire();

    return @intCast(t.splits);
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var t = try Tachyons.init(allocator, input);
    defer t.deinit();

    try t.fire();

    return @intCast(t.paths());
}

const Coord = struct {
    x: usize,
    y: usize,
};
const Cell = enum(u8) {
    empty = '.',
    source = 'S',
    splitter = '^',
    beam = '|',
};
pub const Tachyons = struct {
    width: usize = 0,
    height: usize = 0,
    cells: Array(Cell) = .{},
    alloc: Allocator,
    beams: usize = 0,
    splits: usize = 0,

    pub fn init(allocator: Allocator, str: []const u8) !Tachyons {
        var t = Tachyons{ .alloc = allocator };
        t.width = (std.mem.indexOfScalar(u8, str, '\n') orelse return error.InvalidInput);
        t.height = std.mem.count(u8, str, "\n") + 1;
        var iter = std.mem.splitScalar(u8, str, '\n');
        while (iter.next()) |line| {
            try t.cells.appendSlice(allocator, @ptrCast(line));
        }
        return t;
    }
    pub fn deinit(self: *Tachyons) void {
        self.cells.deinit(self.alloc);
    }
    fn toIdx(self: Tachyons, x: usize, y: usize) usize {
        std.debug.assert(y * self.width + x < self.width * self.height);
        return y * self.width + x;
    }
    fn toCoord(self: Tachyons, idx: usize) Coord {
        std.debug.assert(idx < self.cells.items.len);
        return .{
            .x = @mod(idx, self.width),
            .y = @divFloor(idx, self.width),
        };
    }
    pub fn fire(self: *Tachyons) !void {
        const source = self.toCoord(std.mem.indexOfScalar(Cell, self.cells.items, .source) orelse return error.NoSourceFound);
        try self.placeBeam(.{ .x = source.x, .y = source.y + 1 });
    }
    fn placeBeam(self: *Tachyons, start_coord: Coord) !void {
        for (start_coord.y..self.height) |y| {
            const cell = &self.cells.items[self.toIdx(start_coord.x, y)];
            switch (cell.*) {
                .empty => {
                    cell.* = .beam;
                },
                .beam => {
                    return;
                },
                .splitter => {
                    try self.placeBeam(.{ .x = start_coord.x - 1, .y = y });
                    try self.placeBeam(.{ .x = start_coord.x + 1, .y = y });
                    self.splits += 1;
                    return;
                },
                .source => return error.CantHitSource,
            }
        }
    }
    pub fn paths(self: Tachyons) usize {
        var ret: usize = 0;
        var last: usize = 0;
        for (0..self.height) |y| {
            const slice = self.cells.items[self.toIdx(0, y)..self.toIdx(self.width - 1, y)];
            const cnt = std.mem.count(Cell, slice, &.{.beam});
            if (cnt != last) {
                ret += cnt;
                last = cnt;
            }
        }
        return ret;
    }
    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        for (self.cells.items, 0..) |cell, i| {
            if (i != 0 and @mod(i, self.width) == 0) try writer.writeAll("\n");
            try writer.print("{c}", .{@intFromEnum(cell)});
        }
    }
};

const test_input =
    \\.......S.......
    \\...............
    \\.......^.......
    \\...............
    \\......^.^......
    \\...............
    \\.....^.^.^.....
    \\...............
    \\....^.^...^....
    \\...............
    \\...^.^...^.^...
    \\...............
    \\..^...^.....^..
    \\...............
    \\.^.^.^.^.^...^.
    \\...............
;

test "part 1" {
    const example = test_input;

    const result = try part1(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 21), result);
}

test "part 2" {
    const example = test_input;

    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 40), result);
}
