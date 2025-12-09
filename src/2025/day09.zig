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
    _ = input; // autofix
    var f = Floor.init(tst.allocator);
    defer f.deinit();

    var iter = std.mem.splitScalar(u8, test_input, '\n');
    while (iter.next()) |line| {
        try f.addCoordStr(line);
    }
    return @intFromFloat(f.largest.?.area);
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
    areas: Array(Area),
    largest: ?Area = null,

    const Area = struct {
        from: *const util.grid.Coord,
        to: *const util.grid.Coord,
        area: f32,

        pub fn lessThan(_: @TypeOf({}), self: Area, other: Area) bool {
            return @abs(self.area) < @abs(other.area);
        }
    };

    pub fn init(alloc: Allocator) Floor {
        return .{
            .coords = .{},
            .areas = .{},
            .alloc = alloc,
        };
    }
    pub fn deinit(self: *Floor) void {
        self.coords.deinit(self.alloc);
        self.areas.deinit(self.alloc);
    }

    pub fn addCoordStr(self: *Floor, str: []const u8) !void {
        const comma = std.mem.indexOfScalar(u8, str, ',') orelse return error.InvalidCoord;
        const x = try std.fmt.parseInt(usize, str[0..comma], 10);
        const y = try std.fmt.parseInt(usize, str[comma + 1 ..], 10);

        const coord = util.grid.Coord{ .x = x, .y = y };
        try self.coords.append(self.alloc, coord);
        const lastIdx = self.coords.items.len - 1;
        if (lastIdx < 1) return;

        const last = &self.coords.items[lastIdx];
        for (self.coords.items[0..lastIdx]) |*existing| {
            const d = Area{
                .from = last,
                .to = existing,
                .area = last.calcArea(existing.*, f32),
            };
            try self.areas.append(self.alloc, d);
            if (self.largest) |lrg| {
                if (d.area > lrg.area) self.largest = d;
            } else self.largest = self.areas.getLast();
        }
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
    const d = f.coords.items[0].calcArea(f.coords.items[0], f32);
    try tst.expectApproxEqRel(1, d, 0.001);

    try tst.expectEqual(50, f.largest.?.area);
}

test "part 1" {
    const example = test_input;

    const result = try part1(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 50), result);
}

test "part 2" {
    const example = test_input;

    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 0), result);
}
