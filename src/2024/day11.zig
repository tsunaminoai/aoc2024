const std = @import("std");
const Array = std.ArrayList;
const tst = std.testing;
const Allocator = std.mem.Allocator;
const Thread = std.Thread;

pub const DayNumber = 11;

pub const Answer1 = 8;
pub const Answer2 = 0;

pub fn part1(in: []const u8) f32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var stones = Array(i128).init(alloc);
    defer stones.deinit();

    var iter = std.mem.splitAny(u8, in, " \n");
    while (iter.next()) |number| {
        if (number.len == 0) break;
        stones.append(std.fmt.parseInt(i128, number, 10) catch unreachable) catch unreachable;
    }
    for (0..0) |i| {
        blink(&stones) catch unreachable;
        std.debug.print("blink {} gets {} stones\n", .{ i, stones.items.len });
    }
    return @floatFromInt(stones.items.len);
}
pub fn part2(in: []const u8) f32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stones = Array(i128).init(allocator);
    defer stones.deinit();

    var iter = std.mem.splitAny(u8, in, " \n");
    while (iter.next()) |number| {
        if (number.len == 0) continue;
        stones.append(std.fmt.parseInt(i128, number, 10) catch unreachable) catch unreachable;
    }

    const cpus = std.Thread.getCpuCount() catch unreachable;
    var pool: std.Thread.Pool = undefined;
    pool.init(.{ .allocator = allocator }) catch unreachable;
    defer pool.deinit();

    for (0..75) |iteration| {
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        const alloc = arena.allocator();

        std.debug.print("==Iteration {}==\n", .{iteration});
        var wg = std.Thread.WaitGroup{};
        wg.reset();
        var threads = alloc.alloc(Thread, cpus) catch unreachable;

        var results = alloc.alloc(Array(i128), cpus) catch unreachable;

        const bin_size = if (cpus > stones.items.len) stones.items.len else @divFloor(stones.items.len, cpus);
        // if (bin_size == 0) bin_size = 1;
        // const remainder = @mod(stones.items.len, cpus);
        std.debug.print("Bins of {} size \n", .{bin_size});

        var it = std.mem.window(i128, stones.items, bin_size, bin_size);
        var idx: usize = 0;
        for (threads[0..], 0..) |*t, i| {
            if (it.next()) |bin| {
                if (bin.len == 0) continue;
                const slice: []const i128 = if (i == threads.len - 1) stones.items[bin_size * i ..] else bin[0..];
                results[i] = Array(i128).initCapacity(alloc, bin_size * 2) catch unreachable;
                wg.start();
                // std.debug.print("Giving thread {}: {any}\n", .{ i, slice });
                t.* = Thread.spawn(.{}, worker, .{ &wg, slice, &results[i], i }) catch unreachable;
                idx += 1;
            }
        }
        wg.wait();

        for (0..idx) |i| {
            threads[i].join();
        }
        var new_stones = Array(i128).init(allocator);

        for (0..idx) |i| {
            const res = results[i];
            // std.debug.print("Adding {any}\n", .{res.items});
            new_stones.appendSlice(res.items) catch unreachable;
        }
        // std.debug.print("New stones: {any}\n", .{new_stones.items});
        stones.deinit();
        stones = new_stones;
    }
    // var total_stones: usize = 0;
    // for (results.items) |r| {
    //     total_stones += r.items.len;
    // }

    return @floatFromInt(stones.items.len);
}

pub fn worker(wg: *std.Thread.WaitGroup, stones: []const i128, output: *Array(i128), index: usize) void {
    if (stones.len == 0) return;
    std.debug.print("Thread {} started\n", .{index});
    // std.debug.print("\tGiven {any}\n", .{stones});
    // output.ensureTotalCapacity(stones.len * 2) catch unreachable;
    for (stones) |s| {
        if (s == 0)
            output.*.append(1) catch unreachable
        else {
            const num_digits = comptime_int_log10(s);
            // std.debug.print("{} digits in {}\n", .{ num_digits, s });
            if (num_digits % 2 == 0) {
                const split = comptime_pow10(num_digits / 2);
                output.*.append(@divFloor(s, split)) catch unreachable;
                output.*.append(@mod(s, split)) catch unreachable;
            } else {
                output.*.append(s * 2024) catch unreachable;
            }
        }
    }
    wg.finish();
    std.debug.print("Thread {} completed\n", .{index});
    // std.debug.print("\n\t{} Transformed {any}\n\tto\n\t{any}\n", .{ index, stones, output.items });
}

pub fn blink(stones: *std.ArrayList(i128)) !void {
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
    // try std.testing.expectEqual(55312, part1(test_input));
    try std.testing.expectEqual(55312, part2(test_input));
}

inline fn comptime_int_log10(x: i128) usize {
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

inline fn comptime_pow10(n: usize) i128 {
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
