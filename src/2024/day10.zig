const std = @import("std");
const Array = std.ArrayList;
const tst = std.testing;
const Allocator = std.mem.Allocator;

pub const DayNumber = 10;

pub const Answer1 = 0;
pub const Answer2 = 0;

pub fn part1(in: []const u8) f32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var t = NodeTree.init(alloc, in) catch unreachable;
    defer t.deinit();

    t.find_all_paths() catch unreachable;

    return 0;
}
pub fn part2(in: []const u8) f32 {
    const ret: f32 = 0;
    _ = in;
    return ret;
}

const Elevation = enum(u8) {
    Head = 0,
    Top = 9,
    _,
    pub fn fromChar(char: u8) !Elevation {
        return @enumFromInt(try std.fmt.parseInt(u32, &.{char}, 10));
    }
    pub fn isNextTo(self: Elevation, other: Elevation) bool {
        return if (other == .Head) false else (@intFromEnum(self) == @intFromEnum(other) - 1);
    }
    pub fn format(self: Elevation, _: anytype, _: anytype, writer: anytype) !void {
        const int = @intFromEnum(self) + 48;
        try writer.print("{c}", .{if (self == .Head) 'H' else int});
    }
};

const Position = struct {
    x: i32,
    y: i32,
    pub fn init(x: anytype, y: anytype) Position {
        return Position{ .x = @intCast(x), .y = @intCast(y) };
    }
    pub fn add(self: Position, other: Position) Position {
        return Position{ .x = self.x + other.x, .y = self.y + other.y };
    }
};
const Node = struct {
    elevation: Elevation,
    pos: Position,
    neighbors: Array(*Node),

    pub fn init(alloc: Allocator, x: i32, y: i32, ele: u8) !Node {
        return .{
            .elevation = try Elevation.fromChar(ele),
            .pos = .{ .x = x, .y = y },
            .neighbors = Array(*Node).init(alloc),
        };
    }
    pub fn deinit(self: Node) void {
        self.neighbors.deinit();
    }
    pub fn format(self: Node, _: anytype, _: anytype, writer: anytype) !void {
        try writer.print("{} ({},{})", .{
            self.elevation,
            self.pos.x,
            self.pos.y,
        });
    }

    pub fn continuesPath(self: Node, other: Node) bool {
        return self.elevation.isNextTo(other.elevation);
    }
};

const NodeTree = struct {
    roots: Array(*Node),

    nodes: std.AutoArrayHashMap(Position, Node),
    alloc: Allocator,

    pub fn init(alloc: Allocator, in: []const u8) !NodeTree {
        var tree = NodeTree{
            .roots = Array(*Node).init(alloc),
            .nodes = std.AutoArrayHashMap(Position, Node).init(alloc),
            .alloc = alloc,
        };
        var iter = std.mem.splitScalar(u8, in, '\n');
        var x: i32 = 0;
        while (iter.next()) |line| : (x += 1) {
            for (line, 0..) |char, y| {
                var n = try Node.init(alloc, x, @intCast(y), char);
                errdefer n.deinit();

                if (n.elevation == .Head) try tree.roots.append(&n);
                try tree.nodes.put(.{ .x = x, .y = @intCast(y) }, n);
            }
        }
        std.debug.print("Found {} roots\n", .{tree.roots.items.len});
        return tree;
    }

    pub fn find_all_paths(self: *NodeTree) !void {
        for (self.roots.items) |root| {
            _ = try self.find_path(root);
            break;
        }
    }
    pub fn find_path(self: NodeTree, root: *Node) !?[]*Node {
        var queue = Array(*const Node).init(self.alloc);
        defer queue.deinit();

        try queue.append(root);
        const dirs = .{
            Position.init(-1, 0),
            Position.init(0, -1),
            Position.init(1, 0),
            Position.init(0, 1),
        };
        while (queue.popOrNull()) |check| {
            inline for (dirs) |dir| {
                if (self.nodes.getPtr(check.pos.add(dir))) |node| {
                    std.debug.print("Checking {any} with {any}\n", .{ check, node.* });
                    if (check.continuesPath(node.*)) {
                        std.debug.print("{} continues path\n", .{node.*});
                        try queue.append(node);
                    }
                }
            }
        }

        return null;
    }

    pub fn deinit(self: *NodeTree) void {
        self.roots.deinit();
        // for (self.nodes.items) |*n|
        //     n.deinit();
        self.nodes.deinit();
    }
};

const test_input =
    \\89010123
    \\78121874
    \\87430965
    \\96549874
    \\45678903
    \\32019012
    \\01329801
    \\10456732
;

test {
    try std.testing.expectEqual(0, part1(test_input));
    try std.testing.expectEqual(0, part2(test_input));
}
