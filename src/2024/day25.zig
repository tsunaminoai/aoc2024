const std = @import("std");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;
const lib = @import("lib.zig");
const Error = lib.Error;

pub const DayNumber = 25;
pub const data = @embedFile("data/25.txt");

pub const Answer1 = 3307;
pub const Answer2 = 0;

const PinPattern = struct {
    type: Type = undefined,
    heights: [5]i16 = .{-1} ** 5,
    const Type = enum { Key, Lock };

    pub fn init(in: []const u8) PinPattern {
        var self = PinPattern{
            .type = if (in[0] == '#') .Lock else .Key,
        };
        var line_iter = std.mem.splitScalar(u8, in, '\n');
        _ = line_iter.next();

        var height: i8 = 0;

        while (line_iter.next()) |line| {
            // std.debug.print("{s}\n", .{line});
            for (self.heights[0..], 0..) |*h, i| {
                const check = line[i];
                // std.debug.print("\t{c}\n", .{check});

                if (self.type == .Lock and check == '.' and h.* == -1) {
                    h.* = height;
                    // std.debug.print("Setting pin {} to {}\n", .{ i, height });
                } else if (self.type == .Key and check == '#' and h.* == -1) {
                    h.* = height;
                    // std.debug.print("Setting pin {} to {}\n", .{ i, height });
                }
            }
            height += 1;
        }
        if (self.type == .Key)
            self.flip();
        return self;
    }

    pub fn fits(self: PinPattern, other: PinPattern) bool {
        var ret: u3 = 0;
        for (self.heights[0..], 0..) |h, i| {
            if (h + other.heights[i] <= 5) ret += 1;
        }
        return ret == 5;
    }

    pub fn flip(self: *PinPattern) void {
        for (self.heights[0..], 0..) |h, i| {
            self.heights[i] = 5 - h;
        }
    }
    pub fn deinit(self: PinPattern) void {
        _ = self; // autofix
    }
};

test "lock" {
    var p = PinPattern.init(
        \\#####
        \\.####
        \\.####
        \\.####
        \\.#.#.
        \\.#...
        \\.....
    );
    defer p.deinit();
    const expected = &.{ 0, 5, 3, 4, 3 };

    // std.debug.print("{any}\n", .{p.heights});
    try tst.expectEqualSlices(i16, expected, &p.heights);
}

test "key" {
    var p = PinPattern.init(
        \\.....
        \\#....
        \\#....
        \\#...#
        \\#.#.#
        \\#.###
        \\#####
    );
    defer p.deinit();
    const expected = &.{ 5, 0, 2, 1, 3 };

    // std.debug.print("{any}\n", .{p.heights});
    try tst.expectEqualSlices(i16, expected, &p.heights);
}

pub fn part1(_: std.mem.Allocator, in: []const u8) Error!i64 {
    var ret: i32 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var keys = Array(PinPattern){};
    var locks = Array(PinPattern){};

    defer {
        keys.deinit(alloc);
        locks.deinit(alloc);
    }

    var pat_iter = std.mem.splitSequence(u8, in, "\n\n");
    while (pat_iter.next()) |pat| {
        if (pat.len == 0) continue;
        const p = PinPattern.init(pat);
        if (p.type == .Key)
            keys.append(alloc, p) catch unreachable
        else
            locks.append(alloc, p) catch unreachable;
    }

    for (keys.items) |key| {
        // std.debug.print("{any}\n", .{key});
        for (locks.items) |lock| {
            if (key.fits(lock)) ret += 1;

            // std.debug.print("Key {} fits lock {}\n", .{ key, lock });
        }
    }

    return (ret);
}
pub fn part2(_: std.mem.Allocator, in: []const u8) Error!i64 {
    const ret: i64 = 0;
    _ = in;
    return ret;
}
const test_input =
    \\#####
    \\.####
    \\.####
    \\.####
    \\.#.#.
    \\.#...
    \\.....
    \\
    \\#####
    \\##.##
    \\.#.##
    \\...##
    \\...#.
    \\...#.
    \\.....
    \\
    \\.....
    \\#....
    \\#....
    \\#...#
    \\#.#.#
    \\#.###
    \\#####
    \\
    \\.....
    \\.....
    \\#.#..
    \\###..
    \\###.#
    \\###.#
    \\#####
    \\
    \\.....
    \\.....
    \\.....
    \\#....
    \\#.#..
    \\#.#.#
    \\#####
;

test {
    try std.testing.expectEqual(3, part1(std.testing.allocator, test_input));
    try std.testing.expectEqual(0, part2(std.testing.allocator, test_input));
}
