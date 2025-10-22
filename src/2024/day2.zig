const std = @import("std");
const lib = @import("lib.zig");
const Error = lib.Error;
pub const main = @import("main.zig").main;

pub const DayNumber = 2;

pub const Answer1 = 359;
pub const Answer2 = 418;

fn isLessThan(_: @TypeOf(.{}), a: i32, b: i32) bool {
    return a < b;
}

fn isSafe(levels: []i32) bool {
    const isIncreasing = levels[0] < levels[1];
    var last: i32 = if (isIncreasing) levels[0] - 1 else levels[0] + 1;
    for (levels) |lvl| {
        if (isIncreasing) {
            if (lvl < last) return false;
        } else if (lvl > last) return false;
        if (@abs(lvl - last) > 3 or lvl - last == 0) return false;
        last = lvl;
    }
    return true;
}

pub fn part1(in: []const u8) Error!i64 {
    var ret: i64 = 0;
    var report_it = std.mem.splitAny(u8, in, "\n");

    var buffer: [1024 * 100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);

    const alloc = fba.allocator();

    while (report_it.next()) |line| {
        if (line.len == 0) break;
        var list = std.mem.splitAny(u8, line, " ");
        var num_list = std.ArrayList(i32){};
        defer num_list.deinit(alloc);

        while (list.next()) |tok|
            num_list.append(alloc, std.fmt.parseInt(i32, tok, 10) catch unreachable) catch unreachable;

        if (isSafe(num_list.items)) {
            //             std.debug.print("Report '{s}' is safe\n", .{line});
            ret += 1;
        }
    }

    return ret;
}
pub fn part2(in: []const u8) Error!i64 {
    var ret: i64 = 0;
    var report_it = std.mem.splitAny(u8, in, "\n");

    var buffer: [1024 * 100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);

    const alloc = fba.allocator();

    while (report_it.next()) |line| {
        if (line.len == 0) break;
        var list = std.mem.splitAny(u8, line, " ");
        var num_list = std.ArrayList(i32){};
        defer num_list.deinit(alloc);

        while (list.next()) |tok|
            num_list.append(alloc, std.fmt.parseInt(i32, tok, 10) catch unreachable) catch unreachable;

        if (isSafe(num_list.items)) {
            //             std.debug.print("Report '{s}' is safe\n", .{line});
            ret += 1;
        } else {
            const len = num_list.items.len;
            blk: for (0..len) |i| {
                var tmp = num_list.clone(alloc) catch unreachable;
                defer tmp.deinit(alloc);
                _ = tmp.orderedRemove(i);
                if (isSafe(tmp.items)) {
                    //                     std.debug.print("Report '{s}' is safe by removing level {}\n", .{line, i+1});
                    ret += 1;
                    break :blk;
                }
            }
        }
    }

    return ret;
}

const test_input =
    \\7 6 4 2 1
    \\1 2 7 8 9
    \\9 7 6 2 1
    \\1 3 2 4 5
    \\8 6 4 4 1
    \\1 3 6 7 9
;

test {
    try std.testing.expectEqual(2, part1(test_input));
    try std.testing.expectEqual(4, part2(test_input));
}
