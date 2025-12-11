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
    var s = Servers.init(allocator);
    defer s.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try s.readLine(line);
    }
    const paths = try s.findAllPaths("you", "out");

    return @intCast(paths.items.len);
}

pub fn part2(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var ret: i64 = 0;
    var s = Servers.init(allocator);
    defer s.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try s.readLine(line);
    }

    const paths = try s.findAllPaths("svr", "out");
    const dac = s.nodes.get("dac").?;
    const fft = s.nodes.get("fft").?;

    for (paths.items) |path| {
        if (std.mem.count(Servers.Connection, path.items, &.{dac}) == 0) continue;
        if (std.mem.count(Servers.Connection, path.items, &.{fft}) == 0) continue;
        ret += 1;
    }
    return @intCast(ret);
}

pub const Servers = struct {
    root: ?Connection = null,
    out: ?Connection = null,
    nodes: std.StringArrayHashMap(*Node),
    arena: std.heap.ArenaAllocator,

    pub const Connection = *const Node;
    pub const Node = struct {
        connections: Array(Connection) = .{},
    };

    pub fn init(alloc: Allocator) Servers {
        return .{
            .nodes = .init(alloc),
            .arena = .init(alloc),
        };
    }
    pub fn deinit(self: *Servers) void {
        self.nodes.deinit();
        self.arena.deinit();
    }

    pub fn readLine(self: *Servers, line: []const u8) !void {
        const delim = std.mem.indexOfScalar(u8, line, ':') orelse return error.InvalidInput;
        const nodeId = line[0..delim];
        const sourceNode = try self.getOrMakeNode(nodeId);
        var iter = std.mem.tokenizeScalar(u8, line[delim + 2 ..], ' ');
        while (iter.next()) |connectedNodeId| {
            // std.debug.print("Connecting {s} => {s}\n", .{ nodeId, connectedNodeId });
            const targetNode = try self.getOrMakeNode(connectedNodeId);
            try sourceNode.connections.append(self.arena.allocator(), targetNode);
        }
    }

    pub fn getOrMakeNode(self: *Servers, id: []const u8) !*Node {
        const entry = try self.nodes.getOrPut(id);
        if (!entry.found_existing) {
            const newNodePtr = try self.arena.allocator().create(Node);
            newNodePtr.* = .{};
            entry.value_ptr.* = newNodePtr;
            if (std.mem.eql(u8, id, "you"))
                self.root = newNodePtr;

            if (std.mem.eql(u8, id, "out"))
                self.out = newNodePtr;
        }

        return entry.value_ptr.*;
    }

    pub fn findAllPaths(self: *Servers, from: []const u8, to: []const u8) !Array(Array(Connection)) {
        var ret = Array(Array(Connection)){};
        var current = Array(Connection){};
        defer current.deinit(self.arena.allocator());
        try self.dfs(
            &current,
            self.nodes.get(from) orelse return error.IdNotFound,
            self.nodes.get(to) orelse return error.IdNotFound,
            &ret,
        );
        return ret;
    }
    fn dfs(
        self: *Servers,
        path: *Array(Connection),
        source: Connection,
        target: Connection,
        ret: *Array(Array(Connection)),
    ) !void {
        if (std.mem.indexOfScalar(Connection, path.items, source) != null) return;
        // std.debug.print(" [] => ", .{});
        try path.append(self.arena.allocator(), source);
        if (source == target) {
            // save path
            try ret.append(
                self.arena.allocator(),
                try path.clone(self.arena.allocator()),
            );
            // std.debug.print("hit!\n", .{});
        } else {
            // recurse connections
            for (source.connections.items) |conn|
                try self.dfs(path, conn, target, ret);
        }

        // backtrack
        _ = path.pop();
        // std.debug.print("backtrack < \n", .{});
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
const test_input_2 =
    \\svr: aaa bbb
    \\aaa: fft
    \\fft: ccc
    \\bbb: tty
    \\tty: ccc
    \\ccc: ddd eee
    \\ddd: hub
    \\hub: fff
    \\eee: dac
    \\dac: fff
    \\fff: ggg hhh
    \\ggg: out
    \\hhh: out
    \\hhh: eee
;

test "part 1" {
    const example = test_input;

    const result = try part1(tst.allocator, example);
    try std.testing.expectEqual(@as(i64, 5), result);
}

test "part 2" {
    const example = test_input_2;

    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 2), result);
}
