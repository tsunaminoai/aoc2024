const std = @import("std");
const mvzr = @import("mvzr");

pub const DayNumber = 3;

pub const Answer1 = 0;
pub const Answer2 = 0;

pub fn part1(in: []const u8) f32 {
    const regex = mvzr.Regex.compile("mul\\(([0-9]+),([0-9]+)\\)") orelse unreachable;
    const ret: f32 = 0;
    var iter = regex.iterator(in);
    while (iter.next()) |match| {
        std.debug.print("{any}\n", .{match});
    }
    return ret;
}
pub fn part2(in: []const u8) f32 {
    const ret: f32 = 0;
    _ = in;
    return ret;
}
const test_input =
    \\xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
;

test {
    try std.testing.expectEqual(161, part1(test_input));
    try std.testing.expectEqual(0, part2(test_input));
}
