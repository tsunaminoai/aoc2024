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
    for (0..25) |_|
        blink(&stones) catch unreachable;
    std.debug.print("{}\n", .{stones.items.len});
    return @floatFromInt(stones.items.len);
}
pub fn part2(in: []const u8) f32 {
    const ret: f32 = 0;
    _ = in;
    return ret;
}

pub fn blink(stones: *Array(i64)) !void {
    var idx: usize = 0;
    while (idx < stones.items.len) : (idx += 1) {
        const stone = &stones.items[idx];
        const num_digits = std.math.floor(@log10(@as(f32, @floatFromInt(stone.*)))) + 1;
        if (stone.* == 0) {
            stone.* = 1;
        } else if (@mod(num_digits, 2) == 0) {
            const split: i64 = std.math.pow(i64, 10, @as(i64, @intFromFloat((num_digits / 2))));
            // std.debug.print(
            //     "even digits {} {} {}\n",
            //     .{
            //         stone.*,
            //         @divFloor(stone.*, split),
            //         @mod(stone.*, split),
            //     },
            // );
            const val = stone.*;

            try stones.insert(idx + 1, @mod(val, split));
            stones.items[idx] = @divFloor(val, split);
            idx += 1;
        } else {
            stone.* *= 2024;
        }
    }
    // std.debug.print("{any}\n", .{stones.items});
}

const test_input =
    \\125 17
;

test {
    try std.testing.expectEqual(55312, part1(test_input));
    try std.testing.expectEqual(0, part2(test_input));
}
