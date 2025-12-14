const std = @import("std");
const util = @import("util");
const mvzr = @import("mvzr");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;

// Automatically embedded at compile time
pub const data = @embedFile("data/day12.txt");
pub const DayNumber = 12;

const GridSize = 3;

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

const BitSet = std.bit_set.IntegerBitSet(64);
const PresentShape = struct {
    cells: BitSet = .initEmpty(),
    height: u8 = 0,
    width: u8 = 0,

    min_row: u8 = 0,
    min_col: u8 = 0,

    pub fn init() PresentShape {
        return .{};
    }

    pub fn addCell(self: *PresentShape, row: anytype, col: anytype) void {
        self.cells.set(@intCast((row * 8) + col));
        self.width = @max(self.width, @as(u8, @intCast(col + 1)));
        self.height = @max(self.height, @as(u8, @intCast(row + 1)));
    }
    pub fn hasCell(self: PresentShape, row: anytype, col: anytype) bool {
        if (row >= 8 or col >= 8) return false;
        return self.cells.isSet(@intCast((row * 8) + col));
    }
    pub fn normalize(self: PresentShape) PresentShape {
        var norm = PresentShape.init();

        var min_r: u8 = 8;
        var min_c: u8 = 8;
        for (0..self.height) |row| {
            for (0..self.width) |col| {
                if (self.hasCell(row, col)) {
                    min_r = @min(min_r, @as(u8, @intCast(row)));
                    min_c = @min(min_c, @as(u8, @intCast(col)));
                }
            }
        }
        if (min_r == 8) return norm; // empty

        for (0..self.height) |row| {
            for (0..self.width) |col| {
                if (self.hasCell(row, col)) {
                    norm.addCell(
                        @as(u8, @intCast(row)) - min_r,
                        @as(u8, @intCast(col)) - min_c,
                    );
                }
            }
        }
        return norm;
    }

    pub fn rotateCW(self: PresentShape) PresentShape {
        var rot = PresentShape.init();
        rot.height = self.width;
        rot.width = self.height;

        for (0..self.height) |row| {
            for (0..self.width) |col| {
                if (self.hasCell(@as(u8, @intCast(row)), @as(u8, @intCast(col)))) {
                    const new_r = col;
                    const new_c = row;
                    rot.addCell(@as(u8, @intCast(new_r)), @as(u8, @intCast(new_c)));
                }
            }
        }
        return rot.normalize();
    }

    pub fn getRotations(self: PresentShape, alloc: Allocator) !Array(PresentShape) {
        var rots = Array(PresentShape){};
        var current = self.normalize();
        var seen = std.AutoHashMap(BitSet, void).init(alloc);
        defer seen.deinit();
        for (0..4) |_| {
            if (!seen.contains(current.cells)) {
                try rots.append(alloc, current);
                try seen.put(current.cells, {});
            }
            current = current.rotateCW();
        }
        return rots;
    }
};
const Tree = struct {
    cells: BitSet = .initEmpty(),
    height: u8 = 0,
    width: u8 = 0,

    pub fn init(width: u8, height: u8) Tree {
        return .{
            .height = height,
            .width = width,
        };
    }

    pub fn addCell(self: *Tree, row: u8, col: u8) void {
        std.debug.assert(row < self.height and col < self.width);
        self.cells.set(@intCast((row * 8) + col));
    }
};

pub const Solver = struct {
    alloc: Allocator,
    presents: Array(PresentShape),
    trees: Array(Tree),
    pub fn init(alloc: Allocator) Solver {
        return .{
            .alloc = alloc,
            .presents = .{},
            .trees = .{},
        };
    }
    pub fn deinit(self: *Solver) void {
        self.presents.deinit(self.alloc);
        self.trees.deinit(self.alloc);
    }
    /// try and fit shapes into a region
    pub fn canFitShapes(
        self: *Solver,
        tree: Tree,
        shape_idxes: []const usize,
        shape_counts: []const u8,
        current_idx: usize,
        available: BitSet,
    ) !bool {
        if (current_idx >= shape_idxes.len) return true; // everything is placed
        const shape_idx = shape_idxes[current_idx];
        const count = shape_counts[current_idx];

        // try placing 'count' copies of this shape
        for (0..count) |_| {
            var found = false;
            for (0..tree.height) |row| {
                for (0..tree.width) |col| {
                    // get rotations
                    var rots = try self.presents.items[shape_idx].getRotations(self.alloc);
                    defer rots.deinit(self.alloc);
                    for (rots.items) |rot| {
                        if (canPlace(rot, @as(u8, @intCast(row)), @as(u8, @intCast(col)), tree, available)) {
                            found = true;
                            break;
                        }
                    }
                    if (found) break;
                }
                if (found) break;
            }
            if (!found) return false;
        }
        return self.canFitShapes(tree, shape_idxes, shape_counts, current_idx + 1, available);
    }

    pub fn solveReigion(self: *Solver, region_idx: usize) bool {
        if (region_idx >= self.trees.items.len) return true;

        const tree = self.trees.items[region_idx];
        _ = tree; // autofix
        //TODO: implement
        return false;
    }
};

fn canPlace(present: PresentShape, row: u8, col: u8, tree: Tree, available: BitSet) bool {
    for (0..present.height) |r| {
        for (0..present.width) |c| {
            if (present.hasCell(@as(u8, @intCast(r)), @as(u8, @intCast(c)))) {
                const target_r = row + @as(u8, @intCast(r));
                const target_c = col + @as(u8, @intCast(c));
                if (target_r >= tree.height or target_c >= tree.width) return false;

                const idx: usize = @intCast((target_r * 8) + target_c);
                if (!available.isSet(idx)) return false;
            }
        }
    }
    return true;
}

test "present" {
    var p = PresentShape.init();
    p.addCell(0, 0);
    try tst.expect(p.cells.isSet(0));
    try tst.expectEqual(1, p.height);
    try tst.expectEqual(1, p.width);
    try tst.expect(p.hasCell(0, 0));

    p.addCell(4, 0);
    var n = try p.getRotations(tst.allocator);
    defer n.deinit(tst.allocator);
    std.debug.print("{any}\n{any}\n", .{ p, n.items });
}

test "solver" {
    const t = Tree.init(4, 4);
    var s = Solver.init(tst.allocator);
    var p = PresentShape.init();
    defer s.deinit();
    p.addCell(0, 0);
    p.addCell(0, 1);
    p.addCell(0, 2);
    p.addCell(1, 0);

    p.addCell(2, 0);
    p.addCell(2, 1);
    p.addCell(2, 2);
    try s.trees.append(tst.allocator, t);
    try s.presents.append(tst.allocator, p);
    const ret = try s.canFitShapes(t, &.{0}, &.{9}, 0, .initFull());

    try tst.expect(!ret);
}

const test_input =
    \\0:
    \\###
    \\##.
    \\##.
    \\
    \\1:
    \\###
    \\##.
    \\.##
    \\
    \\2:
    \\.##
    \\###
    \\##.
    \\
    \\3:
    \\##.
    \\###
    \\##.
    \\
    \\4:
    \\###
    \\#..
    \\###
    \\
    \\5:
    \\###
    \\.#.
    \\###
    \\
    \\4x4: 0 0 0 0 2 0
    \\12x5: 1 0 1 0 2 2
    \\12x5: 1 0 1 0 3 2
;

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
