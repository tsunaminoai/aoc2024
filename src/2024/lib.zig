const std = @import("std");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;

pub const Position = struct {
    x: i32 = 0,
    y: i32 = 0,
    pub fn init(x: anytype, y: anytype) Position {
        return .{ .x = @intCast(x), .y = @intCast(y) };
    }
    pub fn add(self: Position, other: Position) Position {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }
    pub fn scale(self: Position, scalar: anytype) Position {
        return .{
            .x = self.x * @as(i32, @intCast(scalar)),
            .y = self.y * @as(i32, @intCast(scalar)),
        };
    }
};
test {
    const p1 = Position.init(1, 1);
    const p2 = p1.scale(4);
    const p3 = p2.add(Position.init(-2, 3));
    try tst.expectEqualDeep(Position.init(2, 7), p3);
}

pub fn Cell(comptime T: type) type {
    return struct {
        pos: Position = .{},
        contents: T,
    };
}

pub fn Grid(comptime T: type) type {
    return struct {
        cells: std.AutoArrayHashMap(Position, Cell(T)),
        height: i32 = 0,
        width: i32 = 0,

        const G = @This();
        pub fn init(alloc: Allocator) G {
            return .{
                .cells = std.AutoArrayHashMap(Position, Cell(T)).init(alloc),
            };
        }
        pub fn deinit(self: *G) void {
            self.cells.deinit();
        }
        fn isInBounds(self: G, pos: Position) bool {
            return pos.x >= 0 and pos.y >= 0 and pos.x <= self.width and pos.y <= self.height;
        }
        pub fn put(self: *G, c: Cell(T)) !void {
            if (self.isInBounds(c.pos)) {
                try self.cells.put(c.pos, c);
            }
        }
        pub fn get(self: G, pos: Position) ?Cell {
            if (self.isInBounds(pos)) {
                return self.cells.get(pos);
            }
            return null;
        }
    };
}
test {
    var g = Grid(u8).init(tst.allocator);
    defer g.deinit();

    g.height = 10;
    g.width = 10;

    try g.put(.{ .contents = 'H', .pos = Position.init(0, 0) });
    try tst.expectEqual(1, g.cells.values().len);
    try tst.expectEqual('H', g.cells.get(Position.init(0, 0)).?.contents);
}
