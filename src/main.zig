const std = @import("std");
const root = @import("root.zig");

const Day = @import("day");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    var d = try root.Day.init(alloc, Day.DayNumber, Day.part1, Day.part2);
    defer d.deinit();
    d.part1.expectedResult = Day.Answer1;
    d.part2.expectedResult = Day.Answer2;

    _ = try d.run();
}
