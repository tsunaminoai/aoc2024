const std = @import("std");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;

pub fn CreateGrid(comptime CellType: type) type {
    return struct {
        width: usize = 0,

        height: usize = 0,
        cells: Array(CellType) = .{},
        alloc: Allocator,
        beams: usize = 0,
        splits: usize = 0,
        memos: Memos,
        const Coord = struct {
            x: usize,
            y: usize,
        };

        const Grid = @This();

        pub fn init(allocator: Allocator, items: []CellType) !Grid {
            return Grid{
                .alloc = allocator,
                .memos = .init(allocator),
                .cells = .{
                    .items = allocator.dupe(CellType, items),
                    .capacity = items.len,
                },
            };
        }
        pub fn deinit(self: *Grid) void {
            self.cells.deinit(self.alloc);
            self.memos.deinit();
        }
        pub fn getCellAt(self: *Grid, x: usize, y: usize) *CellType {
            return self.cells.items[self.toIdx(x, y)];
        }
        fn toIdx(self: Grid, x: usize, y: usize) usize {
            std.debug.assert(y * self.width + x < self.width * self.height);
            return y * self.width + x;
        }
        fn toCoord(self: Grid, idx: usize) Coord {
            std.debug.assert(idx < self.cells.items.len);
            return .{
                .x = @mod(idx, self.width),
                .y = @divFloor(idx, self.width),
            };
        }

        const Memos = std.AutoHashMap(usize, usize);

        fn dfs(self: *Grid, coord: Coord) !usize {
            const node = self.toIdx(coord.x, coord.y);

            if (self.memos.get(node)) |m| return m;

            const cell = self.cells.items[node];

            // Splitter: sum paths from left and right branches
            if (cell == .splitter) {
                var total: usize = 0;
                if (coord.x > 0) {
                    total += try self.dfs(.{ .x = coord.x - 1, .y = coord.y });
                }
                if (coord.x + 1 < self.width) {
                    total += try self.dfs(.{ .x = coord.x + 1, .y = coord.y });
                }
                try self.memos.put(node, total);
                return total;
            }

            // Source or other: recurse downward
            if (coord.y + 1 < self.height) {
                const result = try self.dfs(.{ .x = coord.x, .y = coord.y + 1 });
                try self.memos.put(node, result);
                return result;
            }

            try self.memos.put(node, 1);
            return 1;
        }

        pub fn format(
            self: @This(),
            writer: *std.Io.Writer,
        ) std.Io.Writer.Error!void {
            for (self.cells.items, 0..) |cell, i| {
                if (i != 0 and @mod(i, self.width) == 0) try writer.writeAll("\n");
                try writer.print("{f}", .{cell});
            }
        }
    };
}
