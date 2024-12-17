const std = @import("std");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;
const lib = @import("lib");

pub const DayNumber = 0;

pub const Answer1 = 0;
pub const Answer2 = 0;

pub fn part1(in: []const u8) f32 {
    const ret: f32 = 0;
    _ = in;
    return ret;
}
pub fn part2(in: []const u8) f32 {
    const ret: f32 = 0;
    _ = in;
    return ret;
}
const test_input =
    \\
;

test {
    try std.testing.expectEqual(0, part1(test_input));
    try std.testing.expectEqual(0, part2(test_input));
}

const Processor = struct {
    A: i64 = 0,
    B: i64 = 0,
    C: i64 = 0,
    tape: Array(Intruction),
    outputs: Array(i64),

    var intruction_pointer: usize = 0;
    var isRunning: bool = true;

    pub fn init(alloc: Allocator, a: i64, b: i64, c: i64) Processor {
        return .{
            .A = a,
            .B = b,
            .C = c,
            .tape = Array(Intruction).init(alloc),
            .outputs = Array(i64).init(alloc),
        };
    }
    pub fn load(self: *Processor, in: []const u8) !void {
        var iter = std.mem.splitScalar(u8, in, ',');
        while (iter.next()) |code| {
            try self.tape.append(Intruction.fromInt(try std.fmt.parseInt(u3, code, 10)));
        }
    }
    pub fn run(self: *Processor) !void {
        while (isRunning) {
            try self.tick();
            std.debug.print("Result: {}\n", .{self});
        }
    }

    fn get_operand(self: Processor, comptime T: type) !T {
        const op_idx = intruction_pointer + 1;
        if (op_idx >= self.tape.items.len) return error.OperandBeyondTape;
        const num = self.tape.items[op_idx].toInt(u3);
        return switch (num) {
            0...3 => @intCast(num),
            4 => @intCast(self.A),
            5 => @intCast(self.B),
            6 => @intCast(self.C),
            7 => error.InvalidOperand,
        };
    }
    pub fn tick(self: *Processor) !void {
        if (intruction_pointer >= self.tape.items.len) {
            std.debug.print("Halt\n", .{});
            isRunning = false;
            return;
        }
        const next_op = self.tape.items[intruction_pointer];
        defer intruction_pointer += 2;

        std.debug.print("Processing instruction: {s}\n", .{@tagName(next_op)});
        switch (next_op) {
            // The adv instruction (opcode 0) performs division. The numerator is the value in the A register.
            //  The denominator is found by raising 2 to the power of the instruction's combo operand. (So, an operand
            //  of 2 would divide A by 4 (2^2); an operand of 5 would divide A by 2^B.) The result of the division operation
            //  is truncated to an integer and then written to the A register.
            .adv => {
                const num: i64 = self.A;
                const denom: i64 = @as(i64, 1) << try self.get_operand(u6);
                self.A = @divTrunc(num, denom);
            },
            // The bxl instruction (opcode 1) calculates the bitwise XOR of register B and the instruction's literal operand,
            //   then stores the result in register B.
            .bxl => {
                self.B = self.B ^ try self.get_operand(i64);
            },

            // The bst instruction (opcode 2) calculates the value of its combo operand modulo 8 (thereby keeping only its
            //   lowest 3 bits), then writes that value to the B register.
            .bst => {
                self.B = @mod(try self.get_operand(i64), 8);
            },

            // The jnz instruction (opcode 3) does nothing if the A register is 0. However, if the A register is not zero,
            //   it jumps by setting the instruction pointer to the value of its literal operand; if this instruction jumps,
            //  the instruction pointer is not increased by 2 after this instruction.
            .jnz => {
                if (self.A != 0) {
                    intruction_pointer = try self.get_operand(usize);
                    return;
                }
            },

            // The bxc instruction (opcode 4) calculates the bitwise XOR of register B and register C, then stores the
            //   result in register B. (For legacy reasons, this instruction reads an operand but ignores it.)
            .bxc => {
                self.B = self.B ^ self.C;
            },

            // The out instruction (opcode 5) calculates the value of its combo operand modulo 8, then outputs that value.
            //   (If a program outputs multiple values, they are separated by commas.)
            .out => {
                try self.outputs.append(@mod(try self.get_operand(i64), 8));
            },

            // The bdv instruction (opcode 6) works exactly like the adv instruction except that the result is stored in the
            //   B register. (The numerator is still read from the A register.)
            .bdv => {
                const num: i64 = self.A;
                const denom: i64 = @as(i64, 1) << try self.get_operand(u6);
                self.B = @divTrunc(num, denom);
            },

            // The cdv instruction (opcode 7) works exactly like the adv instruction except that the result is stored in the
            //   C register. (The numerator is still read from the A register.)
            .cdv => {
                const num: i64 = self.A;
                const denom: i64 = @as(i64, 1) << try self.get_operand(u6);
                self.C = @divTrunc(num, denom);
            },
        }
    }

    pub fn deinit(self: *Processor) void {
        self.tape.deinit();
        self.outputs.deinit();
    }

    pub fn format(self: Processor, comptime fmt: []const u8, options: anytype, writer: anytype) !void {
        _ = fmt; // autofix
        _ = options; // autofix
        try writer.print("Registers: A[{}] B[{}] C[{}]  PC: {}  CI: {s}", .{
            self.A,
            self.B,
            self.C,
            intruction_pointer,
            if (intruction_pointer < self.tape.items.len) @tagName(self.tape.items[intruction_pointer]) else "N/A",
        });
    }
};
const Intruction = enum(u3) {
    adv = 0,
    bxl,
    bst,
    jnz,
    bxc,
    out,
    bdv,
    cdv,
    pub fn fromInt(int: u3) Intruction {
        return @enumFromInt(int);
    }
    pub fn toInt(self: Intruction, comptime T: type) T {
        return @as(T, @intFromEnum(self));
    }
};

test {
    var p1 = Processor.init(tst.allocator, 0, 0, 9);
    defer p1.deinit();
    try p1.load("2,6");
    try p1.run();
    try tst.expectEqual(1, p1.B);

    var p2 = Processor.init(tst.allocator, 10, 0, 0);
    defer p2.deinit();
    try p2.load("5,0,5,1,5,4");
    try p2.run();
    try tst.expectEqualSlices(i64, &.{ 0, 1, 2 }, p2.outputs.items);
    // var p = Processor.init(tst.allocator, 729, 0, 0);
    // defer p.deinit();
    // p.C = 9;

    // try p.load("0,1,5,4,3,0");

    // try tst.expectEqual(6, p.tape.items.len);
}
