const std = @import("std");
const util = @import("util");
const mvzr = @import("mvzr");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;

// Automatically embedded at compile time
pub const data = @embedFile("data/day02.txt");
pub const DayNumber = 2;

/// Find all of the invalid IDs and sum their values
pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var result: i64 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, ',');
    while (lines.next()) |line| {
        // Your solution here
        result += try checkRange(allocator, line);
    }

    return result;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator;
    const result: i64 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, ',');
    while (lines.next()) |line| {
        _ = line;
        // Your solution here
    }

    return result;
}
pub fn checkRange(alloc: Allocator, str: []const u8) !i64 {
    _ = alloc; // autofix
    var ret: i64 = 0;
    const split = std.mem.indexOfScalar(u8, str, '-') orelse return error.InvalidRange;
    const first = str[0..split];
    const last = str[split + 1 ..];
    const start = try std.fmt.parseInt(usize, first, 10);
    const end = try std.fmt.parseInt(usize, last, 10);
    std.debug.print("Checking {} to {}\n", .{ start, end });

    var buf: [128]u8 = undefined;

    for (start..end + 1) |i| {
        if (!isValidID(try std.fmt.bufPrint(&buf, "{d}", .{i}))) {
            std.debug.print("Adding {}\n", .{i});
            ret += @intCast(i);
        }
    }

    return ret;
}

/// The ranges are separated by commas (,);
/// each range gives its first ID and last ID separated by a dash (-).
/// Invalid IDs have duplicate digits
pub fn isValidID(str: []const u8) bool {
    if (@mod(str.len, 2) != 0) return true;
    for (0..str.len - 1) |i| {
        for (i + 1..str.len) |j| {
            if (str[i] == str[j]) return false;
        }
        i += 1;
    }
    return true;
}
const test_input =
    \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
;

test "valid ID" {
    try tst.expect(isValidID("12"));
    try tst.expect(!isValidID("11"));
    try tst.expect(!isValidID("22"));
    try tst.expect(!isValidID("99"));
    try tst.expect(isValidID("998"));
    try tst.expect(!isValidID("1010"));
    try tst.expect(isValidID("999"));
    try tst.expect(!isValidID("1212"));
    try tst.expect(!isValidID("99991199"));
}
test "valid range" {
    try tst.expectEqual(33, try checkRange(tst.allocator, "11-22"));
    try tst.expectEqual(1010, try checkRange(tst.allocator, "998-1012"));
    try tst.expectEqual(99, try checkRange(tst.allocator, "95-115"));
    try tst.expectEqual(0, try checkRange(tst.allocator, "1698522-1698528"));
}

test "part 1" {
    const example = test_input;

    const result = try part1(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 1227775554), result);
}

test "part 2" {
    const example = test_input;

    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 0), result);
}
