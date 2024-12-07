const std = @import("std");
const Array = std.ArrayList;
const tst = std.testing;

pub const DayNumber = 7;

pub const Answer1 = 0;
pub const Answer2 = 0;

const Equation = struct {
    result: i32,
    operands: Array(i32),
    valid_mask: ?usize = null,

    pub fn init(alloc: std.mem.Allocator, in: []const u8) !Equation {
        const colon = std.mem.indexOfScalar(u8, in, ':') orelse return error.InvalidEq;
        const res = try std.fmt.parseInt(i32, in[0..colon], 10);
        var list = Array(i32).init(alloc);
        var iter = std.mem.splitScalar(u8, in[colon + 2 ..], ' ');
        while (iter.next()) |num| {
            try list.append(try std.fmt.parseInt(i32, num, 10));
        }

        return .{
            .result = res,
            .operands = list,
        };
    }
    pub fn deinit(self: Equation) void {
        self.operands.deinit();
    }

    pub fn format(self: Equation, _: anytype, _: anytype, writer: anytype) !void {
        try writer.print("{} = ", .{self.result});
        for (self.operands.items, 0..) |num, idx| {
            const select = @as(usize, @intCast(1)) << @intCast(idx);
            try writer.print("{} ", .{num});
            if (self.valid_mask) |mask| {
                if (idx < self.operands.items.len - 1)
                    try writer.print("{s} ", .{if (mask & (select) == select) "*" else "+"});
            }
        }
    }
    const Operator = *const fn (i32, i32) i32;
    pub fn eval(self: Equation, op: Operator) i32 {
        return op(self.operands.items[0], self.operands.items[1]);
    }
    pub fn can_be_evaluated(self: *Equation) !bool {
        var opns = try self.operands.clone();
        defer opns.deinit();

        var acc: i32 = 0;
        const num_operands = opns.items.len;
        const num_operations: usize = (num_operands - 1) * 2;
        for (0..num_operations) |op_mask| {
            acc = opns.items[0];
            for (0..num_operands - 1) |operand_idx| {
                const left = acc;
                const right = opns.items[operand_idx + 1];
                // std.debug.print("{} ", .{left});
                const op = blk: {
                    // std.debug.print("M:b{b:3} ", .{op_mask});
                    // std.debug.print("O:b{b:3} ", .{operand_idx - 1});
                    const select = @as(usize, @intCast(1)) << @intCast(operand_idx + 1 - 1);
                    // std.debug.print("S:b{b:3} ", .{select});

                    if (op_mask & (select) == select) {
                        // std.debug.print("* ", .{});
                        break :blk &Mul;
                    } else {
                        // std.debug.print("+ ", .{});

                        break :blk &Add;
                    }
                };
                // std.debug.print("{} ", .{right});

                acc = op(left, right);
                // std.debug.print("= {}\n", .{acc});
            }

            // std.debug.print("{} ?= {}\n", .{ acc, self.result });
            if (acc == self.result) {
                self.valid_mask = op_mask;
                std.debug.print("{} Evaluates\n", .{self});
                return true;
            }
        }
        std.debug.print("{} Bailed out\n", .{self});
        return false;
    }
};
test {
    var eq = try Equation.init(tst.allocator, "292: 11 6 16 20");
    defer eq.deinit();
    try tst.expect(try eq.can_be_evaluated());

    var eq2 = try Equation.init(tst.allocator, "190: 10 19");
    defer eq2.deinit();
    try tst.expect(try eq2.can_be_evaluated());
}
fn Mul(left: i32, right: i32) i32 {
    return left * right;
}
fn Add(left: i32, right: i32) i32 {
    return left + right;
}

///TODO: Read in equations
///TODO: Evalate swappable operators
///TODO: Evalute if equation is solvable
///TODO: Output sum of solveable equations
pub fn part1(in: []const u8) f32 {
    var ret: i32 = 0;
    var iter = std.mem.splitScalar(u8, in, '\n');
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    var eqs = Array(Equation).init(alloc);
    defer eqs.deinit();

    while (iter.next()) |line| {
        var eq = Equation.init(alloc, line) catch unreachable;
        defer eq.deinit();
        if ((eq.can_be_evaluated() catch unreachable)) {
            std.debug.print("Eq {any} can be evaluated\n", .{eq});
            ret += eq.result;
        }
    }
    std.debug.print("{}\n", .{ret});
    return @floatFromInt(ret);
}
pub fn part2(in: []const u8) f32 {
    const ret: f32 = 0;
    _ = in;
    return ret;
}

const test_input =
    \\190: 10 19
    \\3267: 81 40 27
    \\83: 17 5
    \\156: 15 6
    \\7290: 6 8 6 15
    \\161011: 16 10 13
    \\192: 17 8 14
    \\21037: 9 7 18 13
    \\292: 11 6 16 20
;

test {
    try std.testing.expectEqual(3749, part1(test_input));
    try std.testing.expectEqual(0, part2(test_input));
}
