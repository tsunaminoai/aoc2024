const std = @import("std");

const coord = struct {
    x: i32,
    y: i32,
    pub fn init(x: anytype, y: anytype) coord {
        return coord{ .x = @intCast(x), .y = @intCast(y) };
    }
    pub fn add(self: coord, other: coord) coord {
        return coord{ .x = self.x + other.x, .y = self.y + other.y };
    }
};

pub const DayNumber = 4;

pub const Answer1 = 0;
pub const Answer2 = 0;

pub fn part1(in: []const u8) f32 {
    var ret: f32 = 0;

    const xmas = "XMAS";
    const grid_w = std.mem.indexOfScalar(u8, in, '\n').? + 1;
    const grid_h = in.len / grid_w;
    const kernel = [_]coord{
        .{ .x = 1, .y = 0 },
        .{ .x = 0, .y = 1 },
        .{ .x = -1, .y = 0 },
        .{ .x = 0, .y = -1 },
        .{ .x = 1, .y = 1 },
        .{ .x = -1, .y = 1 },
        .{ .x = -1, .y = -1 },
        .{ .x = 1, .y = -1 },
    };
    loop: for (0..in.len) |idx| {
        const x = idx % grid_w;

        const y = idx / grid_w;
        if (get(
            in,
            @intCast(grid_w),
            coord.init(x, y),
        )) |c| {
            // std.debug.print("{c}\t", .{c});
            if (c == '\n') break :loop;
            if (c != 'X') continue :loop;
            kern: for (kernel) |k| {
                const M_check = coord.init(x, y).add(k);

                if (get(in, @intCast(grid_w), M_check)) |char| {
                    switch (char) {
                        'M' => {
                            if (search_in_direction(
                                in,
                                @intCast(grid_w),
                                M_check,
                                k,
                                xmas,
                            )) {
                                ret += 1;
                                std.debug.print("yay\n", .{});
                            }
                        },
                        else => {
                            continue :loop;
                        },
                    }
                } else continue :kern;
            }
        }
    }
    std.debug.print("Grid: {}x{}\n", .{ grid_w, grid_h });
    return ret;
}
fn search_in_direction(
    in: []const u8,
    w: i32,
    c: coord,
    k: coord,
    xmas: []const u8,
) bool {
    var check = c;
    for (xmas) |cheer| {
        if (!in_bounds(w, check.x, check.y)) {
            return false;
        }
        if (get(in, w, check)) |ch| {
            if (ch != cheer) {
                return false;
            }
        }
        check = check.add(k);
    }
    return true;
}
inline fn in_bounds(w: i32, x: i32, y: i32) bool {
    return x < w - 1 and y < w - 1 and x >= 0 and y >= 0;
}
inline fn get(in: []const u8, w: i32, c: coord) ?u8 {
    if (!in_bounds(w, c.x, c.y)) {
        return null;
    }
    return in[@intCast(c.y * w + c.x)];
}

pub fn part2(in: []const u8) f32 {
    const ret: f32 = 0;
    _ = in;
    return ret;
}
const test_input =
    \\MMMSXXMASM
    \\MSAMXMSMSA
    \\AMXSXMAAMM
    \\MSAMASMSMX
    \\XMASAMXAMM
    \\XXAMMXXAMA
    \\SMSMSASXSS
    \\SAXAMASAAA
    \\MAMMMXMMMM
    \\MXMXAXMASX
;

test {

    // try std.testing.expectEqual(18, part1(test_input));
    try std.testing.expectEqual(0, part2(test_input));
}
