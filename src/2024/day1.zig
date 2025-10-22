const std = @import("std");
const lib = @import("lib.zig");
const Error = lib.Error;
pub const main = @import("main.zig").main;

pub const DayNumber = 1;

pub const Answer1 = 2164381;
pub const Answer2 = 20719933;

fn isLessThan(_: @TypeOf(.{}), a: i32, b: i32) bool {
    return a < b;
}

pub fn part1(in: []const u8) Error!i64 {
    var ret: i64 = 0;
    var line_it = std.mem.splitAny(u8, in, "\n");

    var buffer: [1024 * 100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);

    const alloc = fba.allocator();

    var list1 = std.ArrayList(i32){};
    defer list1.deinit(alloc);
    var list2 = std.ArrayList(i32){};
    defer list2.deinit(alloc);
    while (line_it.next()) |line| {
        var tok_it = std.mem.tokenizeAny(u8, line, " ");
        var tok = tok_it.next() orelse "0";

        list1.append(alloc, std.fmt.parseInt(i32, tok, 10) catch unreachable) catch unreachable;
        tok = tok_it.next() orelse "0";
        list2.append(alloc, std.fmt.parseInt(i32, tok, 10) catch unreachable) catch unreachable;
    }
    std.mem.sort(i32, list1.items, .{}, isLessThan);
    std.mem.sort(i32, list2.items, .{}, isLessThan);

    for (0..list1.items.len) |i| {
        ret += (@abs(list1.items[i] - list2.items[i]));
    }
    return ret;
}
pub fn part2(in: []const u8) Error!i64 {
    var ret: i32 = 0;
    var line_it = std.mem.splitAny(u8, in, "\n");

    var buffer: [1024 * 100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);

    const alloc = fba.allocator();

    var list1 = std.ArrayList(i32){};
    defer list1.deinit(alloc);
    var list2 = std.ArrayList(i32){};
    defer list2.deinit(alloc);
    while (line_it.next()) |line| {
        var tok_it = std.mem.tokenizeAny(u8, line, " ");
        var tok = tok_it.next() orelse break;

        list1.append(alloc, std.fmt.parseInt(i32, tok, 10) catch unreachable) catch unreachable;
        tok = tok_it.next() orelse break;
        list2.append(alloc, std.fmt.parseInt(i32, tok, 10) catch unreachable) catch unreachable;
    }

    for (list1.items) |num| {
        const count: i32 = @intCast(std.mem.count(i32, list2.items, &.{num}));
        if (count > 0) {
            //         std.debug.print("Found {} {} times\t", .{num, count});

            ret += num * count;
            //         std.debug.print("{d:0.2}\n", .{ret});
        }
    }

    return (ret);
}

const test_input =
    \\3   4
    \\4   3
    \\2   5
    \\1   3
    \\3   9
    \\3   3
;

test {
    try std.testing.expectEqual(11, part1(test_input));
    try std.testing.expectEqual(31, part2(test_input));
}
