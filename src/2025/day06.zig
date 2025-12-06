const std = @import("std");
const util = @import("util");
const mvzr = @import("mvzr");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;

// Automatically embedded at compile time
pub const data = @embedFile("data/day06.txt");
pub const DayNumber = 6;

/// Bring in all the collumns of opeations
/// perform the operations
/// Add all the results
pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    var result: i64 = 0;
    var sm = SquidMath.init(allocator);
    defer sm.deinit();

    try sm.readInput(input);
    // std.debug.print("{f}\n", .{sm});
    try sm.eval();
    for (sm.results.items) |res| {
        // std.debug.print("Result: {d}\n", .{res});
        result += res;
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

const SquidMath = struct {
    operands: Array(Array(i64)),
    operators: Array(u8),
    sigfigs: Array(u8),
    results: Array(i64),
    alloc: Allocator,

    pub fn init(alloc: Allocator) SquidMath {
        return SquidMath{
            .operands = .{},
            .operators = .{},
            .results = .{},
            .sigfigs = .{},
            .alloc = alloc,
        };
    }

    pub fn readInput(self: *SquidMath, input: []const u8) !void {
        var lines = std.mem.tokenizeScalar(u8, input, '\n');
        var opers = Array(i64){};
        defer opers.deinit(self.alloc);
        // var columns: usize = 0;
        while (lines.next()) |line| {
            var ops = std.mem.splitAny(u8, line, "\t ");
            while (ops.next()) |token| {
                if (token.len != 0) {
                    // Your solution here
                    if (std.ascii.isDigit(token[0])) {
                        const value = try std.fmt.parseInt(i64, token, 10);
                        try opers.append(self.alloc, value);
                    }
                }
            }

            try self.operands.append(self.alloc, try opers.clone(self.alloc));
            opers.clearAndFree(self.alloc);
            if (lines.peek()) |p| {
                if (std.mem.indexOfAny(u8, p, "+*") != null) break;
            }
        }
        //operators line
        const ops = lines.next() orelse return error.InvalidInput;
        // const columns = self.operands.items[0].items.len;
        var index: usize = 0;

        while (index < ops.len - 1) : (index += 1) {
            if (index >= ops.len) break;
            const op = ops[index];
            try self.operators.append(self.alloc, op);
            const sigs = consume(ops, index + 1);
            try self.sigfigs.append(self.alloc, @as(u8, @intCast(sigs)));
            index += sigs;
        }
    }
    fn consume(str: []const u8, index: usize) usize {
        var ret: usize = 0;
        while (index + ret < str.len and std.ascii.isWhitespace(str[index + ret])) {
            ret += 1;
        }
        return ret;
    }

    pub fn deinit(self: *SquidMath) void {
        for (self.operands.items) |*ops| {
            ops.deinit(self.alloc);
        }
        self.operands.deinit(self.alloc);
        self.operators.deinit(self.alloc);
        self.results.deinit(self.alloc);
        self.sigfigs.deinit(self.alloc);
    }

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        for (self.operands.items, 0..) |ops, i| {
            try writer.print("Operands {d}: ", .{i});
            for (ops.items) |op| {
                try writer.print("{d} ", .{op});
            }
            try writer.print("\n", .{});
        }
        try writer.print("Operators: ", .{});
        for (self.operators.items) |op|
            try writer.print("{c} ", .{op});

        try writer.print("\nSigfigs: ", .{});
        for (self.sigfigs.items) |s|
            try writer.print("{} ", .{s});
    }

    pub fn eval(self: *SquidMath) !void {
        for (self.operators.items, 0..) |op, i| {
            // Your solution here
            var ret: i64 = if (op == '+') 0 else 1;
            for (self.operands.items) |line| {
                switch (op) {
                    '+' => ret += line.items[i],
                    '*' => ret *= line.items[i],
                    else => {},
                }
            }

            try self.results.append(self.alloc, ret);
        }
    }
};

const test_input =
    \\123 328  51 64 
    \\ 45 64  387 23 
    \\  6 98  215 314
    \\*   +   *   +  
;

test "squidmath" {
    var sm = SquidMath.init(tst.allocator);
    defer sm.deinit();

    try sm.readInput(test_input);
    std.debug.print("{f}\n", .{sm});
    try sm.eval();
}

test "part 1" {
    const example = test_input;

    const result = try part1(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 4277556), result);
}

test "part 2" {
    const example = test_input;

    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 0), result);
}
