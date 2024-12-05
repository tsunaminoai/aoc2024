const std = @import("std");

pub const DayNumber = 4;

pub const Answer1 = 0;
pub const Answer2 = 0;

const coord = struct {
    x: i32,
    y: i32,
    pub fn init(x: anytype, y: anytype) coord {
        return .{
            .x = @intCast(x),
            .y = @intCast(y),
        };
    }
    pub fn add(self: coord, other: coord) coord {
        return coord.init(self.x + other.x, self.y + other.y);
    }
};

const grid = struct {
    cells: []u8,
    width: i32,
    height: i32,

    allocator: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator, in: []const u8) !grid {
        const w = (std.mem.indexOfScalar(u8, in, '\n') orelse 1) - 1;
        const h = in.len / w;
        const cells = try alloc.alloc(u8, w * h);
        errdefer alloc.free(cells);

        var idx: usize = 0;
        for (in) |c| {
            if (c == '\n') continue;
            cells[idx] = c;
            idx += 1;
        }
        return .{
            .cells = cells,
            .width = @intCast(w),
            .height = @intCast(h),
            .allocator = alloc,
        };
    }
    pub fn deinit(self: grid) void {
        self.allocator.free(self.cells);
    }
    fn in_bounds(self: grid, check: coord) bool {
        return check.x >= 0 and check.y >= 0 and check.x < self.width and check.y < self.height;
    }
    fn get(self: grid, point: coord) ?u8 {
        if (self.in_bounds(point)) {
            return self.cells[@intCast(point.x * point.y + point.x)];
        }
        return null;
    }
    pub fn format(self: grid, _: anytype, _: anytype, writer: anytype) !void {
        try writer.writeAll("\n");
        for (self.cells, 0..) |c, i| {
            try writer.print("{c}", .{c});
            if (@mod(i, @as(usize, @intCast(self.width))) == 0 and i > 0)
                try writer.writeAll("\n");
        }
    }
    fn find_xmas(self: grid, start: coord, dir: coord, idx: usize) bool {
        const xmas = "XMAS";
        if (idx > xmas.len) return false;
        if (self.get(start)) |s| {
            // std.debug.print("Checking: {} = {c}\n", .{ start, s });
            if (s == xmas[idx]) {
                return if (s == 'S') true else self.find_xmas(start.add(dir), dir, idx + 1);
            } else return false;
        } else return false;
    }
};

pub fn part1(in: []const u8) f32 {
    var ret: f32 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    var g = grid.init(alloc, in) catch unreachable;
    defer g.deinit();
    std.debug.print("\n\n{}\n", .{g});
    for (0..@intCast(g.width)) |w| {
        for (0..@intCast(g.height)) |h| {
            for ([_]i32{ -1, 0, 1 }) |x| {
                for ([_]i32{ -1, 0, 1 }) |y| {
                    ret += if (g.find_xmas(coord.init(w, h), coord.init(x, y), 0)) 1 else 0;
                    // std.debug.print("{any}\n", .{g.find_xmas(coord.init(w, h), coord.init(x, y), 0)});
                }
            }
        }
    }
    // for (0..@intCast(g.width)) |x|
    // std.debug.print("{},0: {c}\n", .{ x, g.get(coord.init(x, 1)) orelse '0' });
    return ret;
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
    try std.testing.expectEqual(18, part1(test_input));
    try std.testing.expectEqual(0, part2(test_input));
}
