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
    var result: usize = 0;
    var i: usize = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var machine = try Machine.init(allocator, line);
        defer machine.deinit();
        const presses = try machine.minPresses();
        std.debug.print("Machine {}: {} presses\n", .{ i, presses });
        i += 1;
        result += presses;
    }

    return @intCast(result);
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

        for (str[1..end], 0..) |light, i| {
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
            if (next[0] != '(') continue;
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

    /// finds min presses in bit field
    /// using Gaussian elimination over GF(2)
    pub fn minPresses(self: *Machine) !usize {
        const m = self.btn_diagrams.items.len;

        // make matrix [A|b] where
        // a row is a light
        // a col is a button
        // last column is the goal
        var mat = try self.alloc.alloc(LightSet, self.numLights);
        defer self.alloc.free(mat);

        for (0..self.numLights) |lightIdx| {
            var row = LightSet.initEmpty();

            // check which buttons affect the light
            for (self.btn_diagrams.items, 0..) |btn, btnIdx| {
                if (btn.isSet(lightIdx))
                    row.set(btnIdx);
            }

            // add the goal state
            if (self.goal.isSet(lightIdx))
                row.set(m);

            mat[lightIdx] = row;
        }

        var pivot_col: usize = 0;
        var pivot_row: usize = 0;

        // Track which columns have pivots
        var pivot_cols = LightSet.initEmpty();

        // Gaussian elimination
        while (pivot_col < m and pivot_row < self.numLights) {
            // find pivot
            var found_pivot = false;
            const pivMaybe = LightSet{ .mask = @as(u64, 1) << @intCast(pivot_col) };
            _ = pivMaybe; // autofix
            for (pivot_row..self.numLights) |row| {
                if (mat[row].isSet(pivot_col)) {
                    // swap rows
                    const tmp = mat[pivot_row];
                    mat[pivot_row] = mat[row];
                    mat[row] = tmp;

                    found_pivot = true;
                    break;
                }
            }
            if (!found_pivot) {
                pivot_col += 1;
                continue;
            }
            pivot_cols.set(pivot_col);

            // eXORterminate
            for (0..self.numLights) |row| {
                if (row != pivot_row and mat[row].isSet(pivot_col)) {
                    mat[row].toggleSet(mat[pivot_row]);
                }
            }

            pivot_row += 1;
            pivot_col += 1;
        }

        // check for row with all zeroes except the goal column
        for (mat) |row| {
            var has_button_set = false;
            for (0..m) |col| {
                if (row.isSet(col)) {
                    has_button_set = true;
                    break;
                }
            }
            // If no buttons are set but goal is set, no solution exists
            if (!has_button_set and row.isSet(m)) {
                return error.NoSolution;
            }
        }

        // Collect free variables (columns without pivots)
        var free_vars = try self.alloc.alloc(usize, m);
        defer self.alloc.free(free_vars);
        var num_free: usize = 0;
        for (0..m) |col| {
            if (!pivot_cols.isSet(col)) {
                free_vars[num_free] = col;
                num_free += 1;
            }
        }

        // Try all combinations of free variables to find minimum
        var min_presses: usize = m + 1;
        const num_combinations: usize = @as(usize, 1) << @intCast(num_free);

        for (0..num_combinations) |combo| {
            var solution = LightSet.initEmpty();

            // Set free variables according to this combination
            for (0..num_free) |i| {
                if ((combo & (@as(usize, 1) << @intCast(i))) != 0) {
                    solution.set(free_vars[i]);
                }
            }

            // Back substitution for pivot variables
            var row_idx: usize = self.numLights;
            while (row_idx > 0) {
                row_idx -= 1;
                const row = mat[row_idx];

                // find leading variable (first set button in this row)
                var lead_col: ?usize = null;
                for (0..m) |col| {
                    if (row.isSet(col)) {
                        lead_col = col;
                        break;
                    }
                }

                if (lead_col) |col| {
                    // Start with the goal bit for this row
                    var val = row.isSet(m);

                    // XOR with already determined button values
                    for (col + 1..m) |j| {
                        if (row.isSet(j) and solution.isSet(j)) {
                            val = !val;
                        }
                    }

                    if (val)
                        solution.set(col)
                    else
                        solution.unset(col);
                }
            }

            // Count presses for this solution
            const presses = solution.count();
            if (presses < min_presses) {
                min_presses = presses;
            }
        }

        return min_presses;
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
    const sol = try m.minPresses();
    std.debug.print("{}\n", .{sol});
    try tst.expectEqual(2, sol);
}

test "part 1" {
    const example = test_input;

    const result = try part1(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 7), result);
}

test "part 2" {
    const example = test_input;

    const result = try part2(std.testing.allocator, example);
    try std.testing.expectEqual(@as(i64, 0), result);
}
