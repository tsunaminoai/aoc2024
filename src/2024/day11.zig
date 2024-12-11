const std = @import("std");
const Array = std.ArrayList;
const tst = std.testing;
const Allocator = std.mem.Allocator;

pub const DayNumber = 11;

pub const Answer1 = 222461;
pub const Answer2 = 0;

pub fn part1(in: []const u8) f32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var stones = Array(i64).init(alloc);
    defer stones.deinit();

    var iter = std.mem.splitAny(u8, in, " \n");
    while (iter.next()) |number| {
        if (number.len == 0) break;
        stones.append(std.fmt.parseInt(i64, number, 10) catch unreachable) catch unreachable;
    }
    for (0..25) |i| {
        blink(&stones) catch unreachable;
        std.debug.print("blink {} gets {} stones\n", .{ i, stones.items.len });
    }
    return @floatFromInt(stones.items.len);
}
pub fn part2(in: []const u8) f32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var stones = Array(i64).init(alloc);
    defer stones.deinit();

    var iter = std.mem.splitAny(u8, in, " \n");
    while (iter.next()) |number| {
        if (number.len == 0) break;
        stones.append(std.fmt.parseInt(i64, number, 10) catch unreachable) catch unreachable;
    }
    for (0..75) |i| {
        blink(&stones) catch unreachable;
        std.debug.print("blink {} gets {} stones\n", .{ i, stones.items.len });
    }
    return @floatFromInt(stones.items.len);
}
pub fn blink(stones: *std.ArrayList(i64)) !void {
    // Preallocate memory to avoid frequent reallocations
    try stones.ensureTotalCapacity(stones.items.len * 2);

    var idx: usize = 0;
    while (idx < stones.items.len) : (idx += 1) {
        const stone = &stones.items[idx];
        if (stone.* == 0) {
            stone.* = 1;
        } else {
            const num_digits = comptime_int_log10(stone.*);
            if (num_digits % 2 == 0) {
                // std.debug.print("{}\n", .{num_digits});
                const split = comptime_pow10(num_digits / 2);
                const val = stone.*;
                try stones.insert(idx + 1, @mod(val, split));
                stones.items[idx] = @divFloor(val, split);
                idx += 1;
            } else {
                stone.* *= 2024;
            }
        }
    }
}

const test_input =
    \\125 17
;

test {
    try std.testing.expectEqual(55312, part1(test_input));
    try std.testing.expectEqual(0, part2(test_input));
}

inline fn comptime_int_log10(x: i64) usize {
    return switch (x) {
        0...9 => 1,
        10...99 => 2,
        100...999 => 3,
        1000...9999 => 4,
        10000...99999 => 5,
        100000...999999 => 6,
        1000000...9999999 => 7,
        10000000...99999999 => 8,
        100000000...999999999 => 9,
        1000000000...9999999999 => 10,
        10000000000...99999999999 => 11,
        100000000000...999999999999 => 12,
        1000000000000...9999999999999 => 13,
        10000000000000...99999999999999 => 14,
        100000000000000...999999999999999 => 15,
        1000000000000000...9999999999999999 => 16,
        else => 19,
    };
}

inline fn comptime_pow10(n: usize) i64 {
    // std.debug.print("{}\n", .{n});
    return switch (n) {
        0 => 1,
        1 => 10,
        2 => 100,
        3 => 1000,
        4 => 10000,
        5 => 100000,
        6 => 1000000,
        7 => 10000000,
        8 => 100000000,
        9 => 1000000000,
        10 => 10000000000,
        11 => 100000000000,
        12 => 1000000000000,
        13 => 10000000000000,
        14 => 100000000000000,
        15 => 1000000000000000,
        16 => 10000000000000000,
        else => 0,
    };
}
