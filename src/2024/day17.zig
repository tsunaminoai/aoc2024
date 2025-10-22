const std = @import("std");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;
const lib = @import("lib.zig");
const Error = lib.Error;
pub const main = @import("main.zig").main;

pub const DayNumber = 17;

pub const Answer1 = 0;
pub const Answer2 = 0;

pub fn part1(in: []const u8) Error!i64 {
    const ret: i64 = 0;
    _ = in;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    var p = Processor.init(alloc, 27575648, 0, 0);
    defer p.deinit();

    p.load("2,4,1,2,7,5,4,1,1,3,5,5,0,3,3,0") catch unreachable;
    p.run() catch unreachable;

    var str = Array(u8){};
    defer str.deinit(alloc);
    for (p.outputs.items, 0..) |o, i| {
        str.append(alloc, @intCast(o + 48)) catch unreachable;
        if (i < p.outputs.items.len - 1) {
            str.append(alloc, ',') catch unreachable;
        }
    }
    std.debug.print("'{s}'\n", .{str.items});

    return ret;
}

fn worker(start: usize, len: usize, results: *Array(i64)) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    for (start..start + len) |inputA| {
        var p: *Processor = alloc.create(Processor) catch unreachable;
        defer alloc.destroy(p);
        if (inputA % 100_000 == 0) std.debug.print("{}\n", .{inputA});
        p.* = Processor.init(alloc, inputA, 0, 0);
        defer p.deinit();

        p.load("2,4,1,2,7,5,4,1,1,3,5,5,0,3,3,0") catch unreachable;
        p.run() catch {};

        if (std.mem.eql(u64, p.outputs.items, &.{ 2, 4, 1, 2, 7, 5, 4, 1, 1, 3, 5, 5, 0, 3, 3, 0 })) {
            results.append(alloc, @intCast(inputA)) catch unreachable;
        }
    }
}

pub fn part2(in: []const u8) Error!i64 {
    const ret: i64 = 0;
    _ = in;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const num_threads = std.Thread.getCpuCount() catch unreachable;
    const batch_size = 100_000;
    _ = batch_size; // autofix

    var pool: std.Thread.Pool = undefined;
    pool.init(.{
        .allocator = alloc,
        .n_jobs = @intCast(num_threads),
    }) catch unreachable;
    defer pool.deinit();
    var wait_group: std.Thread.WaitGroup = undefined;
    wait_group.reset();

    var results = Array(i64){};
    defer results.deinit(alloc);

    // var idx: usize = 40_900_000;
    // while (idx < 100_000_000) {
    //     wait_group.reset();
    //     for (num_threads) |_| {
    //         pool.spawn(worker, .{
    //             idx,
    //             batch_size,
    //             &results,
    //         }) catch unreachable;
    //         idx += batch_size;
    //     }
    //     pool.waitAndWork(&wait_group);
    //     if (results.getLastOrNull()) |_| {
    //         std.mem.sort(i64, results.items, .{}, isLessThan);
    //         ret = @floatFromInt(results.items[0]);
    //         break;
    //     }
    // }

    std.debug.print("\n\n{}\n\n", .{ret});
    return 0;
}
fn isLessThan(_: @TypeOf(.{}), a: i64, b: i64) bool {
    return a < b;
}
const test_input =
    \\
;

test {
    // try std.testing.expectEqual(0, part1(test_input));
    // try std.testing.expectEqual(0, part2(test_input));
}

const Processor = struct {
    A: u64 = 0,
    B: u64 = 0,
    C: u64 = 0,
    tape: Array(Intruction),
    outputs: Array(u64),

    intruction_pointer: usize = 0,
    isRunning: bool = true,
    allocator: Allocator,

    pub fn init(alloc: Allocator, a: u64, b: u64, c: u64) Processor {
        return .{
            .allocator = alloc,
            .A = a,
            .B = b,
            .C = c,
            .tape = Array(Intruction){},
            .outputs = Array(u64){},
            .intruction_pointer = 0,
            .isRunning = true,
        };
    }
    pub fn load(self: *Processor, in: []const u8) !void {
        var iter = std.mem.splitScalar(u8, in, ',');
        while (iter.next()) |code| {
            try self.tape.append(self.allocator, Intruction.fromInt(try std.fmt.parseInt(u3, code, 10)));
        }
    }
    pub fn run(self: *Processor) !void {
        while (self.isRunning) {
            try self.tick();
            // std.debug.print("Result: {}\n", .{self});
        }
    }

    fn get_operand(self: Processor, comptime T: type, isLiteral: bool) !T {
        const op_idx = self.intruction_pointer + 1;
        if (op_idx >= self.tape.items.len) return error.OperandBeyondTape;
        const num = self.tape.items[op_idx].toInt(u3);
        if (isLiteral) return num;
        return switch (num) {
            0...3 => @intCast(num),
            4 => @intCast(self.A),
            5 => @intCast(self.B),
            6 => @intCast(self.C),
            7 => error.InvalidOperand,
        };
    }
    pub fn tick(self: *Processor) !void {
        if (self.intruction_pointer >= self.tape.items.len - 1) {
            // std.debug.print("Halt\n", .{});
            self.isRunning = false;
            return;
        }
        const next_op = self.tape.items[self.intruction_pointer];

        // std.debug.print("Processing instruction: {s}\n", .{@tagName(next_op)});
        switch (next_op) {
            // The adv instruction (opcode 0) performs division. The numerator is the value in the A register.
            //  The denominator is found by raising 2 to the power of the instruction's combo operand. (So, an operand
            //  of 2 would divide A by 4 (2^2); an operand of 5 would divide A by 2^B.) The result of the division operation
            //  is truncated to an integer and then written to the A register.
            .adv => {
                const num: u64 = self.A;
                const denom: u64 = @as(u64, 1) << @truncate(@as(u64, @intCast(try self.get_operand(i64, false))));
                self.A = @divTrunc(num, denom);
            },
            // The bxl instruction (opcode 1) calculates the bitwise XOR of register B and the instruction's literal operand,
            //   then stores the result in register B.
            .bxl => {
                self.B = self.B ^ try self.get_operand(u64, true);
            },

            // The bst instruction (opcode 2) calculates the value of its combo operand modulo 8 (thereby keeping only its
            //   lowest 3 bits), then writes that value to the B register.
            .bst => {
                // std.debug.print("\t{}\n", .{
                //     try self.get_operand(u64, false),
                // });
                self.B = @mod(try self.get_operand(u64, false), 8);
            },

            // The jnz instruction (opcode 3) does nothing if the A register is 0. However, if the A register is not zero,
            //   it jumps by setting the instruction pointer to the value of its literal operand; if this instruction jumps,
            //  the instruction pointer is not increased by 2 after this instruction.
            .jnz => {
                if (self.A != 0) {
                    self.intruction_pointer = try self.get_operand(usize, true);
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
                try self.outputs.append(self.allocator, @mod(try self.get_operand(u64, false), 8));
            },

            // The bdv instruction (opcode 6) works exactly like the adv instruction except that the result is stored in the
            //   B register. (The numerator is still read from the A register.)
            .bdv => {
                const num: u64 = self.A;
                const denom: u64 = @as(u64, 1) << try self.get_operand(u6, false);
                self.B = @divTrunc(num, denom);
            },

            // The cdv instruction (opcode 7) works exactly like the adv instruction except that the result is stored in the
            //   C register. (The numerator is still read from the A register.)
            .cdv => {
                const num: u64 = self.A;
                const denom: u64 = @as(u64, 1) << @truncate(@as(u64, @intCast(try self.get_operand(i64, false))));
                self.C = @divTrunc(num, denom);
            },
        }
        self.intruction_pointer += 2;
    }

    pub fn deinit(self: *Processor) void {
        self.tape.deinit(self.allocator);
        self.outputs.deinit(self.allocator);
    }

    pub fn format(self: Processor, comptime fmt: []const u8, options: anytype, writer: anytype) !void {
        _ = fmt; // autofix
        _ = options; // autofix
        try writer.print("Registers: A[{}] B[{}] C[{}]  PC: {}  CI: {s}", .{
            self.A,
            self.B,
            self.C,
            self.intruction_pointer,
            if (self.intruction_pointer < self.tape.items.len) @tagName(self.tape.items[self.intruction_pointer]) else "N/A",
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

test "1" {
    var p1 = Processor.init(tst.allocator, 0, 0, 9);
    defer p1.deinit();
    try p1.load("2,6");
    try p1.run();
    try tst.expectEqual(1, p1.B);
}
test "2" {
    var p2 = Processor.init(tst.allocator, 10, 0, 0);
    defer p2.deinit();
    try p2.load("5,0,5,1,5,4");

    try p2.run();
    try tst.expectEqual(6, p2.tape.items.len);
    try tst.expectEqualSlices(u64, &.{ 0, 1, 2 }, p2.outputs.items);
}

test "3" {
    var p = Processor.init(tst.allocator, 2024, 0, 0);
    defer p.deinit();
    try p.load("0,1,5,4,3,0");

    try p.run();

    try tst.expectEqual(0, p.A);
    try tst.expectEqualSlices(
        u64,
        &.{ 4, 2, 5, 6, 7, 7, 7, 7, 3, 1, 0 },
        p.outputs.items,
    );
}

test "4" {
    var p = Processor.init(tst.allocator, 0, 29, 0);
    defer p.deinit();
    try p.load("1,7");

    try p.run();

    try tst.expectEqual(26, p.B);
}

test "5" {
    var p = Processor.init(tst.allocator, 0, 2024, 43690);
    defer p.deinit();
    try p.load("4,0");

    try p.run();

    try tst.expectEqual(44354, p.B);
}

test "larger" {
    var p = Processor.init(tst.allocator, 729, 0, 0);
    defer p.deinit();
    try p.load("0,1,5,4,3,0");

    try p.run();

    try tst.expectEqualSlices(
        u64,
        &.{ 4, 6, 3, 5, 6, 3, 5, 2, 1, 0 },
        p.outputs.items,
    );
}
