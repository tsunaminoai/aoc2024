const std = @import("std");

pub const DayNumber = 5;

pub const Answer1 = 0;
pub const Answer2 = 0;

pub fn part1(in: []const u8) f32 {
    const ret: f32 = 0;
    _ = in;
    return ret;
}
pub fn part2(in: []const u8) f32 {
    const ret: f32 = 0;
    _ = in;
    return ret;
}
const test_input =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
;

test {
    try std.testing.expectEqual(143, part1(test_input));
    try std.testing.expectEqual(0, part2(test_input));
}
