const std = @import("std");
const util = @import("util");
const mvzr = @import("mvzr");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;

// Automatically embedded at compile time
pub const data = @embedFile("data/day01.txt");
pub const DayNumber = 1;

pub fn part1(allocator: std.mem.Allocator, input: []const u8) !i64 {
    _ = allocator; // autofix
    const result: i64 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        _ = line; // autofix
        // Your solution here
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

const LightSet = std.bit_set.IntegerBitSet(64);
const Machine = struct {
    lights: LightSet = .initEmpty(),
    btn_diagrams: Array(LightSet) = .{},
    joltage_reqs: []const u8 = "",
    running: bool = false,
    goal: LightSet = .initEmpty(),
    numLights: usize = 0,
    alloc: Allocator,

    /// inits machine with all lights off
    pub fn init(alloc: Allocator, str: []const u8) !Machine {
        var m: Machine = .{
            .alloc = alloc,
        };
        var next = try m.parseLights(str);
        next = try m.parseButtons(str[next + 1 ..]);

        return m;
    }
    pub fn deinit(self: *Machine) void {
        self.btn_diagrams.deinit(self.alloc);
    }
    fn parseLights(self: *Machine, str: []const u8) !usize {
        const end = std.mem.indexOf(u8, str, "]") orelse return error.InvalidString;

        for (str[1 .. end - 1], 0..) |light, i| {
            switch (light) {
                '#' => self.goal.set(i),
                '.' => self.goal.unset(i),
                else => return error.InvalidLightState,
            }
            self.numLights += 1;
        }
        return end;
    }
    fn parseButtons(self: *Machine, str: []const u8) !usize {
        const end = std.mem.lastIndexOfScalar(u8, str, ')') orelse return error.InvalidString;
        var iter = std.mem.splitScalar(u8, str[0 .. end + 1], ' ');
        while (iter.next()) |next| {
            if (next.len == 0) continue;
            var lightIndexes = LightSet.initEmpty();
            var iner = std.mem.tokenizeAny(u8, next, "(),");
            while (iner.next()) |num| {
                lightIndexes.set(try std.fmt.parseInt(usize, num, 10));
            }

            try self.btn_diagrams.append(self.alloc, lightIndexes);
        }
        return end;
    }

    /// will start if indicator lights match those shown in the diagram
    /// . == off, # == on
    pub fn start(self: *Machine) !void {
        if (!self.lights.eql(self.goal)) return error.ExpensiveNoises;
        self.running = true;
    }

    /// toggles all the lights per the button's digagram
    pub fn pushButton(self: *Machine, btnIdx: usize) void {
        const wires = self.btn_diagrams.items[btnIdx];

        self.lights.toggleSet(wires);
    }
};

const test_input =
    \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
    \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
    \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
;
test "machine" {
    var m = try Machine.init(tst.allocator, "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1)");
    defer m.deinit();
    std.debug.print("{b:0>8}\n", .{m.lights.mask});
    try tst.expectEqual(0b0000, m.lights.mask);
    try tst.expectEqual(0b0110, m.goal.mask);
    try tst.expectError(error.ExpensiveNoises, m.start());
    m.pushButton(0);
    std.debug.print("{b:0>8}\n", .{m.lights.mask});
    try tst.expectEqual(0b1000, m.lights.mask);
}

test "part 1" {
    // const example = test_input;

    // const result = try part1(std.testing.allocator, example);
    // try std.testing.expectEqual(@as(i64, 7), result);
}

test "part 2" {
    const example = test_input;

    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 0), result);
}
