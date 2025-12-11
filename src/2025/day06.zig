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
    var result: i64 = 0;
    var sm = SquidMath.init(allocator);
    defer sm.deinit();

    try sm.readInput(input);
    // std.debug.print("{f}\n", .{sm});
    try sm.squidIt();
    for (sm.results.items) |res| {
        // std.debug.print("Result: {d}\n", .{res});
        result += res;
    }

    return result;
}

const SquidMath = struct {
    operands: Array(Array(i64)),
    operators: Array(u8),
    results: Array(i64),
    alloc: Allocator,

    pub fn init(alloc: Allocator) SquidMath {
        return SquidMath{
            .operands = .{},
            .operators = .{},
            .results = .{},
            .alloc = alloc,
        };
    }

    pub fn readInput(self: *SquidMath, input: []const u8) !void {
        var lines = std.mem.tokenizeScalar(u8, input, '\n');

        var opers = Array(i64){};

        defer opers.deinit(self.alloc);

        while (lines.next()) |line| {
            var ops = std.mem.splitAny(u8, line, "\t ");

            while (ops.next()) |token| {
                if (token.len == 0) continue;

                // Your solution here

                if (std.ascii.isDigit(token[0])) {
                    const value = try std.fmt.parseInt(i64, token, 10);

                    try opers.append(self.alloc, value);
                } else {
                    try self.operators.append(self.alloc, token[0]);
                }

                // std.debug.print("{s}|", .{token});
            }

            if (opers.items.len > 0) {
                try self.operands.append(self.alloc, try opers.clone(self.alloc));

                opers.clearAndFree(self.alloc);
            }
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

    pub fn squidIt(self: *SquidMath) !void {
        for (self.operators.items, 0..) |op, i| {
            var actual = try self.transformColumn(i);
            std.debug.print("Transformed: {any}\n", .{actual.items});
            defer actual.deinit(self.alloc);
            var ret: i64 = if (op == '+') 0 else 1;
            for (actual.items) |val| {
                switch (op) {
                    '+' => ret += val,
                    '*' => ret *= val,
                    else => {},
                }
            }
            try self.results.append(self.alloc, ret);
        }
    }

    // right to left
    // top to bottom
    fn transformColumn(
        self: SquidMath,
        col: usize,
    ) !Array(i64) {
        if (col >= self.operands.items[0].items.len) return error.InvalidColumn;
        var orig = Array(i64){};
        defer orig.deinit(self.alloc);
        var sf: usize = 0;
        for (self.operands.items) |line| {
            try orig.append(self.alloc, line.items[col]);
            const s = countDigits(orig.getLast());
            sf = @max(s, sf);
        }
        var ret = Array(i64){};
        try ret.appendNTimes(self.alloc, 0, self.operands.items.len);
        std.debug.print("Working on: {any} ({})\n", .{ orig.items, sf });

        for (0..sf) |digit_pos| {
            for (orig.items) |operand| {
                const d = get_digit(operand, digit_pos);
                ret.items[digit_pos] *= 10;
                ret.items[digit_pos] += d;
            }
            // Remove trailing zeros from the built number
            while (ret.items[digit_pos] > 0 and @mod(ret.items[digit_pos], 10) == 0) {
                ret.items[digit_pos] = @divFloor(ret.items[digit_pos], 10);
            }
        }

        return ret;
    }

    fn get_digit(number: anytype, pos: usize) @TypeOf(number) {

        // Calculate power of 10 for the position
        var divisor: @TypeOf(number) = 1;
        for (0..pos) |_|
            divisor *= 10;

        // Extract the digit
        return @mod(@divFloor(number, divisor), 10);
    }

    fn countDigits(number: i64) usize {
        if (number == 0) return 1;
        var n = @abs(number);
        var count: usize = 0;
        while (n > 0) {
            count += 1;
            n = @divFloor(n, 10);
        }
        return count;
    }
};

const test_input =
    \\123 328  51 64 
    \\ 45 64  387 23 
    \\  6 98  215 314
    \\*   +   *   +  
;
// [0] = 356 * 24 * 1

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
    try std.testing.expectEqual(@as(i64, 3263827), result);
}
