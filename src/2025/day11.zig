const std = @import("std");
const util = @import("util");
const mvzr = @import("mvzr");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;

// Automatically embedded at compile time
pub const data = @embedFile("data/day11.txt");
pub const DayNumber = 11;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    const result: i64 = 0;
    var s = Servers.init(allocator);
    defer s.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try s.readLine(line);
    }
    for (s.nodes.keys()) |ent| {
        std.debug.print("{s}\n", .{ent});
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

pub const Servers = struct {
    root: ?Node = null,
    out: ?Node = null,
    nodes: std.StringArrayHashMap(Node),
    alloc: Allocator,

    pub const Connection = Node;
    pub const Node = struct {
        connections: Array(Connection) = .{},
    };

    pub fn init(alloc: Allocator) Servers {
        return .{
            .alloc = alloc,
            .nodes = .init(alloc),
        };
    }
    pub fn deinit(self: *Servers) void {
        self.nodes.deinit();
    }

    pub fn readLine(self: *Servers, line: []const u8) !void {
        const delim = std.mem.indexOfScalar(u8, line, ':') orelse return error.InvalidInput;
        const nodeId = line[0..delim];
        var newNode = try self.getOrMakeNode(nodeId);
        var iter = std.mem.tokenizeScalar(u8, line[delim + 2 ..], ' ');
        while (iter.next()) |connectedNodeId| {
            // std.debug.print("Connecting {s} => {s}\n", .{ nodeId, connectedNodeId });
            const mentionedNode = try self.getOrMakeNode(connectedNodeId);
            try newNode.connections.append(self.alloc, mentionedNode);
        }
    }

    pub fn getOrMakeNode(self: *Servers, id: []const u8) !Node {
        const newNode = try self.nodes.getOrPut(id);
        if (!newNode.found_existing) {
            if (std.mem.eql(u8, id, "you")) {
                // std.debug.print("Root Set to {s}\n", .{id});
                self.root = newNode.value_ptr.*;
            }
            if (std.mem.eql(u8, id, "out")) {
                // std.debug.print("Out Set to {s}\n", .{id});
                self.out = newNode.value_ptr.*;
            }
            newNode.value_ptr.* = Node{};
        }

        return newNode.value_ptr.*;
    }
};

const test_input =
    \\aaa: you hhh
    \\you: bbb ccc
    \\bbb: ddd eee
    \\ccc: ddd eee fff
    \\ddd: ggg
    \\eee: out
    \\fff: out
    \\ggg: out
    \\hhh: ccc fff iii
    \\iii: out
;

test "part 1" {
    const example = test_input;
    var arena = std.heap.ArenaAllocator.init(tst.allocator);
    defer arena.deinit();

    const result = try part1(arena.allocator(), example);
    _ = result; // autofix
    // try std.testing.expectEqual(@as(i64, 5), result);
}

test "part 2" {
    const example = test_input;

    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 0), result);
}
