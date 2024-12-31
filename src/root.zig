const std = @import("std");
const models = @import("models.zig");
test {
    testing.refAllDecls(models);
}
const testing = std.testing;

pub const Half = struct {
    part: u2 = 0,
    testContents: ?[]const u8 = null,
    expectedResult: f32 = 0,
    actualResult: f32 = 0,
    runFn: TestFn,
    runTime: i128 = 0,

    pub fn init(alloc: std.mem.Allocator, day: u8, half: u1, testFn: TestFn) !Half {
        const infile = try std.fmt.allocPrint(alloc, "inputs/2024/{}.txt", .{day});
        defer alloc.free(infile);
        var file = try std.fs.cwd().openFile(infile, .{});
        defer file.close();

        return .{
            .part = half,
            .runFn = testFn,
            .testContents = try file.readToEndAlloc(alloc, 100_000),
        };
    }
    pub fn deinit(self: Half, alloc: std.mem.Allocator) void {
        if (self.testContents) |tc| alloc.free(tc);
    }

    pub fn run(self: *Half) bool {
        const start = std.time.nanoTimestamp();
        self.actualResult = self.runFn(self.testContents.?);
        self.runTime = std.time.nanoTimestamp() - start;
        const ret = self.actualResult == self.expectedResult;
        if (!ret) std.log.err("Part {} failed. Expected '{}' got '{d:0.2}'", .{
            self.part,
            self.expectedResult,
            self.actualResult,
        });
        std.debug.print(
            "Part {} took {d:0.3}ms\n",
            .{
                self.part + 1,
                @as(f32, @floatFromInt(self.runTime)) / std.time.ns_per_ms,
            },
        );
        return ret;
    }
};
const TestFn = *const fn ([]const u8) f32;
fn day1Test(in: []const u8) f32 {
    var ret: f32 = 0;
    for (in) |c| {
        ret += if (c == '(') 1 else if (c == ')') -1 else 0;
    }
    return ret;
}
fn day2Test(in: []const u8) f32 {
    var ret: f32 = 0;
    const idx: usize = blk: for (in, 0..) |c, i| {
        ret += if (c == '(') 1 else if (c == ')') -1 else 0;
        if (ret == -1) break :blk i;
    } else 0;

    return @floatFromInt(idx + 1);
}
test {
    var d = try Day.init(std.testing.allocator, 0, day1Test, day2Test);
    d.part1.expectedResult = 138;
    d.part2.expectedResult = 1771;
    defer d.deinit();
    try std.testing.expect(d.run());
}

pub const Day = struct {
    number: u8,
    part1: Half,
    part2: Half,

    allocator: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator, day: u8, part1: TestFn, part2: TestFn) !Day {
        return .{
            .number = day,
            .part1 = try Half.init(alloc, day, 0, part1),
            .part2 = try Half.init(alloc, day, 1, part2),
            .allocator = alloc,
        };
    }
    pub fn deinit(self: Day) void {
        self.part1.deinit(self.allocator);
        self.part2.deinit(self.allocator);
    }

    pub fn run(self: *Day) bool {
        std.debug.print("Running Day {}\n", .{self.number});
        return self.part1.run() and self.part2.run();
    }
};
