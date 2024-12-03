const std = @import("std");
const mvzr = @import("mvzr");

pub const DayNumber = 3;

pub const Answer1 = 174336360;
pub const Answer2 = 0;

pub fn part1(in: []const u8) f32 {
    const regex = mvzr.Regex.compile("mul\\(([0-9]+),([0-9]+)\\)") orelse unreachable;
    var ret: i32 = 0;
    var line_iter = std.mem.splitScalar(u8, in, '\n');
    while (line_iter.next()) |line| {
        var iter = regex.iterator(line);
        while (iter.next()) |match| {
            const numbers = match.slice[4 .. match.slice.len - 1];
            // std.debug.print("numbers:{s}\n", .{numbers});

            const split_idx = std.mem.indexOf(u8, numbers, ",") orelse unreachable;
            const num1 = std.fmt.parseInt(i32, numbers[0..split_idx], 10) catch unreachable;
            const num2 = std.fmt.parseInt(i32, numbers[split_idx + 1 ..], 10) catch unreachable;
            const mul = num1 * num2;
            ret += mul;
            // std.debug.print("{} x {} = {}: {}\n", .{ num1, num2, mul, ret });
        }
    }
    return @floatFromInt(ret);
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
