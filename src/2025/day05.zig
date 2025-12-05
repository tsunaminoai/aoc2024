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
    var ret: i64 = 0;
    var sections = std.mem.splitSequence(u8, input, "\n\n");
    const db_section = sections.next() orelse return error.InvalidInput;
    var db = Database.init(allocator);
    defer db.deinit();

    try db.readDBFromString(db_section);
    try db.optimize();

    for (db.ranges.items) |r| {
        // std.debug.print("{any}\n", .{r});
        ret += r.num(i64);
    }

    return ret;
}

const Range = struct {
    start: usize,
    stop: usize,

    pub fn contains(self: Range, value: usize) bool {
        return self.start <= value and value <= self.stop;
    }
    pub fn validIds(self: Range, db: *Database) !void {
        for (self.start..self.stop + 1) |id| {
            try db.ids.put(id, id);
        }
    }
    pub fn num(self: Range, comptime T: type) T {
        return @as(T, @intCast(self.stop - self.start + 1));
    }
    pub fn isLessThan(_: @TypeOf(.{}), self: Range, other: Range) bool {
        return self.start < other.start;
    }
};
const Database = struct {
    ranges: Array(Range) = .{},
    alloc: Allocator,

    pub fn init(alloc: Allocator) Database {
        return .{
            .ranges = .{},
            .alloc = alloc,
        };
    }
    pub fn deinit(self: *Database) void {
        self.ranges.deinit(self.alloc);
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
        try self.ranges.append(self.alloc, newRange);
    }
    pub fn optimize(self: *Database) !void {
        if (self.ranges.items.len == 0) return;

        // std.debug.print("Starting with {} records.\n", .{self.ranges.items.len});

        // Sort by start position
        std.mem.sort(Range, self.ranges.items, .{}, Range.isLessThan);

        // Single pass merge
        var write_idx: usize = 0;
        for (1..self.ranges.items.len) |read_idx| {
            const current = self.ranges.items[read_idx];
            var last = &self.ranges.items[write_idx];

            // Check if current overlaps or is adjacent to last
            if (current.start <= last.stop + 1) {
                // Merge: extend last range
                last.stop = @max(last.stop, current.stop);
            } else {
                // No overlap: move to next slot
                write_idx += 1;
                self.ranges.items[write_idx] = current;
            }
        }

        self.ranges.items.len = write_idx + 1;
        // std.debug.print("Ending with {} records.\n", .{self.ranges.items.len});
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
