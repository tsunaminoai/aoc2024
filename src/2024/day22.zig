const std = @import("std");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;
const lib = @import("lib.zig");
const Error = lib.Error;
pub const DayNumber = 22;

pub const Answer1 = 14119253575;
pub const Answer2 = 0;

pub fn part1(in: []const u8) Error!i64 {
    var ret: i64 = 0;
    var iter = std.mem.splitScalar(u8, in, '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;

        var p = Prng{};
        const num = std.fmt.parseInt(u64, line, 10) catch unreachable;
        p.init(num);
        p.run(2000);
        const result = p.get();
        ret += @intCast(result);
        // std.debug.print("{}: {}\n", .{ num, result });
    }
    // std.debug.print("{}\n", .{ret});
    return (ret);
}
pub fn part2(in: []const u8) Error!i64 {
    const ret: i64 = 0;
    _ = in;
    return ret;
}

pub const Prng = struct {
    const state = struct {
        var value: u64 = 0;
    };

    pub fn init(self: Prng, value: u64) void {
        _ = self; // autofix
        state.value = value;
    }
    fn prune(self: Prng) void {
        _ = self; // autofix
        state.value = @mod(state.value, 16777216);
    }
    fn mix(self: Prng, val: u64) void {
        _ = self; // autofix
        state.value = state.value ^ val;
    }

    pub fn round(self: *Prng) void {
        const res1 = state.value * 64;
        self.mix(res1);
        self.prune();
        const res2 = @divFloor(state.value, 32);
        self.mix(res2);
        self.prune();
        const res3 = state.value * 2048;
        self.mix(res3);
        self.prune();
    }

    pub fn run(self: *Prng, rounds: usize) void {
        for (0..rounds) |_| {
            self.round();
        }
    }
    pub fn get(self: Prng) u64 {
        _ = self; // autofix
        return state.value;
    }
};

test {
    var p = Prng{};
    p.init(42);
    p.mix(15);
    try tst.expectEqual(37, p.get());
}

test {
    var p1 = Prng{};
    p1.init(1);
    p1.run(2000);
    try tst.expectEqual(8685429, p1.get());
}

const test_input =
    \\1
    \\10
    \\100
    \\2024
;

test {
    try std.testing.expectEqual(37327623, part1(test_input));
    try std.testing.expectEqual(0, part2(test_input));
}
