const std = @import("std");
const Array = std.ArrayList;
const tst = std.testing;

pub const DayNumber = 7;

pub const Answer1 = 12553187650171;
pub const Answer2 = 0;

const Equation = struct {
    result: i64,
    operands: Array(i64),
    valid_mask: ?usize = null,

    pub fn init(alloc: std.mem.Allocator, in: []const u8) !Equation {
        const colon = std.mem.indexOfScalar(u8, in, ':') orelse return error.InvalidEq;
        const res = try std.fmt.parseInt(i64, in[0..colon], 10);
        var list = Array(i64).init(alloc);
        var iter = std.mem.splitScalar(u8, in[colon + 2 ..], ' ');
        while (iter.next()) |num| {
            try list.append(try std.fmt.parseInt(i64, num, 10));
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
            try writer.print("{}", .{num});
            if (self.valid_mask) |mask| {
                if (idx < self.operands.items.len - 1) {
                    try writer.print(" {s} ", .{if (mask & (select) == select) "*" else "+"});
                }
            } else if (idx < self.operands.items.len - 1) try writer.writeAll(" ? ");
        }
    }
    const Operator = *const fn (i64, i64) i64;
    pub fn eval(self: Equation, op: Operator) i64 {
        return op(self.operands.items[0], self.operands.items[1]);
    }
    pub fn can_be_evaluated(self: *Equation) !bool {
        var opns = try self.operands.clone();
        defer opns.deinit();

        var acc: i64 = 0;
        const num_operands = opns.items.len;
        const operations: usize = @as(usize, @intCast(1)) << @intCast(num_operands - 1);
        // std.debug.print("Evaluating: {} with {} {b:0>4} ops\n", .{ self, operations, operations });
        for (0..operations) |op_vec| {
            acc = opns.items[0];
            // std.debug.print("Evaluating: {} with vector {b:0>4}\n", .{ self, op_vec });
            for (0..num_operands - 1) |op_idx| {
                const left = acc;
                const right = opns.items[op_idx + 1];
                // std.debug.print("{} ", .{left});
                const op = blk: {
                    // std.debug.print("O:b{b:0>4} ", .{op_idx});
                    const select = @as(usize, @intCast(1)) << @intCast(op_idx);
                    // std.debug.print("S:b{b:0>4} ", .{select});

                    if (op_vec & (select) == select) {
                        // std.debug.print("* ", .{});
                        break :blk &Mul;
                    } else {
                        // std.debug.print("+ ", .{});

                        break :blk &Add;
                    }
                };
                // std.debug.print("{} ", .{right});

                acc = op(left, right);
                // if (acc > self.result) return false;
                // std.debug.print("= {}\n", .{acc});
            }

            // std.debug.print("{} ?= {}\n", .{ acc, self.result });
            if (acc == self.result) {
                self.valid_mask = op_vec;
                // std.debug.print("{} Evaluates\n", .{self});
                return true;
            }
        }
        // std.debug.print("{} Bailed out\n", .{self});
        return false;
    }
};
test {
    var eq = try Equation.init(tst.allocator, "292: 11 6 16 20");
    defer eq.deinit();
    // try tst.expect(try eq.can_be_evaluated());
}
test {
    var eq2 = try Equation.init(tst.allocator, "44: 2 2 2 2 2 2 2");
    defer eq2.deinit();
    try tst.expect(try eq2.can_be_evaluated());
}
fn Mul(left: i64, right: i64) i64 {
    return left * right;
}
fn Add(left: i64, right: i64) i64 {
    return left + right;
}

///TODO: Read in equations
///TODO: Evalate swappable operators
///TODO: Evalute if equation is solvable
///TODO: Output sum of solveable equations
pub fn part1(in: []const u8) f32 {
    var ret: i64 = 0;
    var iter = std.mem.splitScalar(u8, in, '\n');
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    var eqs = Array(Equation).init(alloc);
    defer eqs.deinit();

    while (iter.next()) |line| {
        if (line.len == 0) continue;
        var eq = Equation.init(alloc, line) catch unreachable;
        defer eq.deinit();
        // std.debug.print("Loading: {s}\n", .{line});
        if ((eq.can_be_evaluated() catch unreachable)) {
            ret += eq.result;
            // std.debug.print("{} += {}\n", .{ ret - eq.result, eq });
        }
    }
    // std.debug.print("{}\n", .{ret});
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

fn generate_combinations_fn(
    choices: []const OpFn,
    combination: []OpFn,
    pos: usize,
    patterns: *Array([]OpFn),
) !void {
    if (pos == combination.len) {
        try patterns.append(combination);
        return;
    }

    for (choices) |choice_fn| {
        combination[pos] = choice_fn;
        try generate_combinations_fn(
            choices,
            combination,
            pos + 1,
            patterns,
        );
    }
    return;
}

const OpFn = *const fn (i64, i64) i64;
const OpChoices = &[_]OpFn{
    &Add,
    &Mul,
};

test "recursion with function pointers" {
    var n: [2]OpFn = undefined;
    // const choices = [_]ChoiceFunction{ choice0, choice1, choice2 };
    var pats = Array([]OpFn).init(tst.allocator);
    defer pats.deinit();
    try generate_combinations_fn(OpChoices, &n, 0, &pats);
    const something = eval_patterns(3267, &.{ 81, 40, 27 }, pats.items);
    if (something) |found|
        std.debug.print("{any}\n", .{found}); // else
    // return error.OhGod;
}

fn eval_patterns(check: i64, operands: []const i64, patterns: [][]OpFn) ?[]OpFn {
    for (patterns) |pat| {
        // std.debug.print("Pattern: {any} = ", .{pat});
        var acc: i64 = operands[0];
        for (pat, 0..) |op, i| {
            acc = op(acc, operands[i + 1]);
        }
        // std.debug.print("{}\n", .{acc});
        if (acc == check) return pat;
    }
    return null;
}
