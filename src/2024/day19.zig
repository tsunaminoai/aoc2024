const std = @import("std");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;
const lib = @import("lib");

pub const DayNumber = 19;

pub const Answer1 = 0;
pub const Answer2 = 0;

pub fn part1(in: []const u8) f32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var d = Self.init(alloc);
    defer d.deinit();

    d.load(in) catch unreachable;
    const ret = d.check();
    return @floatFromInt(ret);
}
pub fn part2(in: []const u8) f32 {
    const ret: f32 = 0;
    _ = in;
    return ret;
}

const Self = @This();

const Design = struct {
    design: []u8,
    isValid: bool = false,
};
const Pattern = []u8;

patterns: Array([]u8) = undefined,
designs: Array(Design) = undefined,
allocator: Allocator,
fn init(alloc: Allocator) Self {
    return .{
        .allocator = alloc,
        .patterns = Array([]u8).init(alloc),
        .designs = Array(Design).init(alloc),
    };
}

fn check(self: Self) usize {
    var ret: usize = 0;

    des: for (self.designs.items) |d| {
        var idx: usize = 0;
        var pat_idx: usize = 0;
        while (pat_idx < self.patterns.items.len) {
            const p = self.patterns.items[pat_idx];
            if (std.mem.startsWith(u8, d.design[idx..], p)) {
                idx += p.len;
                std.debug.print("\t{s} has {s}\n", .{ d.design, p });

                // std.debug.print("\t{} =?= {}\n", .{ idx, d.design.len - 1 });

                if (idx == d.design.len) {
                    std.debug.print("\tAdded {s}\n", .{d.design});

                    ret += 1;
                    continue :des;
                } else {
                    pat_idx = 0;
                }
            } else pat_idx += 1;
        }
        std.debug.print("\nFailed {s}\n", .{d.design});
    }
    std.debug.print("{}\n", .{ret});
    return ret;
}

fn isLessThan(_: @TypeOf(.{}), a: Pattern, b: Pattern) bool {
    return b.len < a.len;
}

fn load(self: *Self, in: []const u8) !void {
    var split = std.mem.splitSequence(u8, in, "\n\n");
    const pats = split.next().?;
    const des = split.next().?;
    {
        var iter = std.mem.splitScalar(u8, pats, ',');
        while (iter.next()) |pat| {
            const trim = std.mem.trim(u8, pat, "\n ");
            const pattern = try self.allocator.alloc(u8, trim.len);
            errdefer self.allocator.free(pattern);

            @memcpy(pattern, trim);

            try self.patterns.append(pattern);
        }
    }
    std.mem.sort(Pattern, self.patterns.items, .{}, isLessThan);

    // for (self.patterns.items) |p| std.debug.print("Pattern: {s}\n", .{p});

    {
        var iter = std.mem.splitScalar(u8, des, '\n');
        while (iter.next()) |d| {
            const trim = std.mem.trim(u8, d, "\n ");
            const design = try self.allocator.alloc(u8, trim.len);
            errdefer self.allocator.free(design);

            @memcpy(design, trim);

            try self.designs.append(.{ .design = design });
        }
    }
    // for (self.designs.items) |d| std.debug.print("Design: {s}\n", .{d.design});
    std.debug.print("Loaded {} patterns and {} designs\n", .{ self.patterns.items.len, self.designs.items.len });
}
test {
    var d = Self.init(tst.allocator);
    defer d.deinit();

    try d.load(test_input);
    try tst.expectEqual(6, d.check());
}

fn deinit(self: Self) void {
    for (self.patterns.items) |p|
        self.allocator.free(p);
    self.patterns.deinit();

    for (self.designs.items) |d|
        self.allocator.free(d.design);
    self.designs.deinit();
}
const test_input =
    \\r, wr, b, g, bwu, rb, gb, br
    \\
    \\brwrr
    \\bggr
    \\gbbr
    \\rrbgbr
    \\ubwu
    \\bwurrg
    \\brgr
    \\bbrgwb
;

test {
    try std.testing.expectEqual(6, part1(test_input));
    try std.testing.expectEqual(0, part2(test_input));
}
