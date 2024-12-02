const std = @import("std");

pub const DayNumber = 0;

pub const Answer1 = 138;
pub const Answer2 = 1771;

pub fn part1(in: []const u8) f32 {
    var ret: f32 = 0;
    for (in) |c| {
        ret += if (c == '(') 1 else if (c == ')') -1 else 0;
    }
    return ret;
}
pub fn part2(in: []const u8) f32 {
    var ret: f32 = 0;
    const idx: usize = blk: for (in, 0..) |c, i| {
        ret += if (c == '(') 1 else if (c == ')') -1 else 0;
        if (ret == -1) break :blk i;
    } else 0;

    return @floatFromInt(idx + 1);
}
