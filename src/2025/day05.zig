const std = @import("std");
const util = @import("util");
const mvzr = @import("mvzr");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;

// Automatically embedded at compile time
pub const data = @embedFile("data/day05.txt");
pub const DayNumber = 5;

/// The fresh ID ranges are inclusive: the range 3-5 means that ingredient IDs 3, 4, and 5 are all fresh.
/// The ranges can also overlap; an ingredient ID is fresh if it is in any range.
/// The Elves are trying to determine which of the available ingredient IDs are fresh.
pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var result: i64 = 0;

    var sections = std.mem.splitSequence(u8, input, "\n\n");
    const db_section = sections.next() orelse return error.InvalidInput;
    const ids = sections.next() orelse return error.InvalidInput;
    var db = Database.init(allocator);
    defer db.deinit();

    try db.readDBFromString(db_section);

    var iter = std.mem.tokenizeScalar(u8, ids, '\n');
    while (iter.next()) |id| {
        const id_i = try std.fmt.parseInt(usize, id, 10);
        if (db.isFresh(id_i)) result += 1;
    }

    return result;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var sections = std.mem.splitSequence(u8, input, "\n\n");
    const db_section = sections.next() orelse return error.InvalidInput;
    var db = Database.init(allocator);
    defer db.deinit();

    try db.readDBFromString(db_section);

    return db.ids.count();
}

const Range = struct {
    start: usize,
    stop: usize,

    pub fn contains(self: Range, value: usize) bool {
        return self.start <= value and value <= self.stop;
    }
    pub fn validIds(self: Range, alloc: Allocator) ![]usize {
        var ret = Array(usize){};
        defer ret.deinit(alloc);

        for (self.start..self.stop + 1) |id| {
            try ret.append(alloc, id);
        }

        return try ret.toOwnedSlice(alloc);
    }
};
const Database = struct {
    ranges: Array(Range) = .{},
    alloc: Allocator,
    ids: std.AutoHashMap(usize, usize),

    pub fn init(alloc: Allocator) Database {
        return .{
            .ranges = .{},
            .alloc = alloc,
            .ids = std.AutoHashMap(usize, usize).init(alloc),
        };
    }
    pub fn deinit(self: *Database) void {
        self.ranges.deinit(self.alloc);
        self.ids.deinit();
    }
    pub fn readDBFromString(self: *Database, str: []const u8) !void {
        var lines = std.mem.tokenizeScalar(u8, str, '\n');
        while (lines.next()) |line| {
            var split = std.mem.splitScalar(u8, line, '-');
            const start = try std.fmt.parseInt(usize, split.next() orelse return error.InvalidRange, 10);
            const stop = try std.fmt.parseInt(usize, split.next() orelse return error.InvalidRange, 10);
            try self.addRange(start, stop);
        }
    }

    pub fn addRange(self: *Database, start: usize, stop: usize) !void {
        const newRange = Range{ .start = start, .stop = stop };
        const newIds = try newRange.validIds(self.alloc);
        defer self.alloc.free(newIds);

        for (newIds) |id| {
            try self.ids.put(id, id);
        }

        try self.ranges.append(self.alloc, newRange);
    }
    pub fn isFresh(self: Database, id: usize) bool {
        for (self.ranges.items) |r| {
            if (r.contains(id)) return true;
        }
        return false;
    }
};
/// The database operates on ingredient IDs. It consists of a list of fresh ingredient ID ranges,
/// a blank line, and a list of available ingredient IDs. For example:
const test_input =
    \\3-5
    \\10-14
    \\16-20
    \\12-18
    \\
    \\1
    \\5
    \\8
    \\11
    \\17
    \\32
;

test "range" {
    const ret = try (Range{ .start = 3, .stop = 5 }).validIds(tst.allocator);
    defer tst.allocator.free(ret);
    try tst.expectEqual(3, ret.len);
}

test "part 1" {
    const example = test_input;

    const result = try part1(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 3), result);
}

test "part 2" {
    const example = test_input;

    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 14), result);
}
