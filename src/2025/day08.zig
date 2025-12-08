const std = @import("std");
const util = @import("util");
const mvzr = @import("mvzr");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;

// Automatically embedded at compile time
pub const data = @embedFile("data/day08.txt");
pub const DayNumber = 8;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    const result: i64 = 0;

    var p = Playground.init(allocator);
    defer p.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var iter = std.mem.splitScalar(u8, line, ',');

        try p.addBox(
            try std.fmt.parseInt(i64, iter.next() orelse return error.InvalidInput, 10),
            try std.fmt.parseInt(i64, iter.next() orelse return error.InvalidInput, 10),
            try std.fmt.parseInt(i64, iter.next() orelse return error.InvalidInput, 10),
        );
    }

    return result;
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator; // autofix
    const result: i64 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        _ = line; // autofix
        // Your solution here
    }

    return result;
}

const CurcuitId = usize;
const BoxId = usize;
const Position = struct {
    x: i64 = 0,
    y: i64 = 0,
    z: i64 = 0,
    pub fn distance(self: Position, other: Position) i64 {
        const xx = self.x * other.x;
        const yy = self.y * other.y;
        const zz = self.z * other.z;

        return std.math.sqrt(@as(usize, @intCast(xx + yy + zz)));
    }
};
const Connection = struct {
    to: BoxId = math.maxInt(BoxId),
    from: BoxId = math.maxInt(BoxId),
    len: i64 = math.maxInt(i64),
    pub fn swapped(self: Connection) Connection {
        return .{
            .to = self.from,
            .from = self.to,
            .len = self.len,
        };
    }
};
const JunctionBox = struct {
    pos: Position = .{},
    id: BoxId = 0,
    alloc: Allocator,

    pub fn init(a: Allocator, x: anytype, y: anytype, z: anytype, id: CurcuitId) JunctionBox {
        return .{
            .alloc = a,
            .pos = .{
                .x = @intCast(x),
                .y = @intCast(y),
                .z = @intCast(z),
            },
            .id = id,
        };
    }
    pub fn distance(self: JunctionBox, other: JunctionBox) i64 {
        return self.pos.distance(other.pos);
    }
};

/// 3d environment
/// find closest that arent already directly connected
/// look for shortest loops
/// return the sum of the largest 3
const Playground = struct {
    jboxes: std.AutoArrayHashMap(usize, JunctionBox),
    maxId: usize = 0,
    alloc: Allocator,
    connections: std.AutoHashMap(Connection, Connection),

    pub fn init(alloc: Allocator) Playground {
        return .{
            .alloc = alloc,
            .jboxes = .init(alloc),
            .connections = .init(alloc),
        };
    }
    pub fn deinit(self: *Playground) void {
        self.jboxes.deinit();
        self.connections.deinit();
    }

    pub fn addBox(self: *Playground, x: i64, y: i64, z: i64) !void {
        const box = JunctionBox.init(self.alloc, x, y, z, self.maxId);

        try self.jboxes.put(self.maxId, box);
        self.maxId += 1;
    }

    /// By connecting these two junction boxes together, because electricity can flow between them,
    /// they become part of the same circuit. After connecting them, there is a single circuit which
    /// contains two junction boxes, and the remaining 18 junction boxes remain in their own individual
    ///  circuits.
    /// Now, the two junction boxes which are closest together but aren't already directly connected
    ///  are 162,817,812 and 431,825,988. After connecting them, since 162,817,812 is already connected
    ///  to another junction box, there is now a single circuit which contains three junction boxes and
    /// an additional 17 circuits which contain one junction box each.
    pub fn connectBoxes(self: *Playground) !void {
        var iter = self.jboxes.iterator();
        while (iter.next()) |ent| {
            const box = ent.value_ptr.*;
            var inner = self.jboxes.iterator();
            var conn = Connection{
                .from = box.id,
            };
            while (inner.next()) |other| {
                const box2 = other.value_ptr.*;

                if (conn.from == box2.id) continue;
                const dist = box.distance(box2);
                if (dist < conn.len) {
                    conn.to = box2.id;
                    conn.len = dist;
                }
            }

            if (self.connections.get(conn) != null or self.connections.get(conn.swapped()) != null) continue;
            try self.connections.put(conn, conn);
        }
    }
};

const test_input =
    \\162,817,812
    \\57,618,57
    \\906,360,560
    \\592,479,940
    \\352,342,300
    \\466,668,158
    \\542,29,236
    \\431,825,988
    \\739,650,466
    \\52,470,668
    \\216,146,977
    \\819,987,18
    \\117,168,530
    \\805,96,715
    \\346,949,466
    \\970,615,88
    \\941,993,340
    \\862,61,35
    \\984,92,344
    \\425,690,689
;

test "playground" {
    var p = Playground.init(tst.allocator);
    defer p.deinit();

    var lines = std.mem.tokenizeScalar(u8, test_input, '\n');
    while (lines.next()) |line| {
        var iter = std.mem.splitScalar(u8, line, ',');

        try p.addBox(
            try std.fmt.parseInt(i64, iter.next() orelse return error.InvalidInput, 10),
            try std.fmt.parseInt(i64, iter.next() orelse return error.InvalidInput, 10),
            try std.fmt.parseInt(i64, iter.next() orelse return error.InvalidInput, 10),
        );
    }

    try tst.expectEqual(20, p.jboxes.values().len);

    try p.connectBoxes();
    var iter = p.connections.valueIterator();
    while (iter.next()) |conn| {
        std.debug.print("Connection: {any}\n", .{conn});
    }
}

test "part 1" {
    const example = test_input;

    const result = try part1(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 0), result);
}

test "part 2" {
    const example = test_input;

    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 0), result);
}
