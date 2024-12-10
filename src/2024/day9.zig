const std = @import("std");
const Array = std.ArrayList;
const tst = std.testing;
const Allocator = std.mem.Allocator;

pub const DayNumber = 9;

pub const Answer1 = 6154342787400;
pub const Answer2 = 0;

pub fn part1(in: []const u8) f32 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const b = read_blocks(alloc, in) catch unreachable;
    defer alloc.free(b);

    defrag(b);
    defrag(b);

    // for (b) |bl| {
    //     for (bl.size) |_|
    //         if (bl.id) |id|
    //             std.debug.print("[{}]", .{id})
    //         else
    //             std.debug.print(".", .{});
    // }
    // std.debug.print("\n", .{});
    std.debug.print("Checkum: {}\n", .{checksum(b)});
    return @floatFromInt(checksum(b));
}
pub fn part2(in: []const u8) f32 {
    const ret: f32 = 0;
    _ = in;
    return ret;
}
const test_input =
    \\2333133121414131402
;
const test_representation =
    \\00...111...2...333.44.5555.6666.777.888899
;
const test_defreg =
    \\0099811188827773336446555566..............
;
const Block = struct {
    id: ?i64 = null,
    size: usize = 0,
};

var free_count: usize = 0;

fn read_blocks(alloc: Allocator, line: []const u8) ![]Block {
    var blocks = Array(Block).init(alloc);
    var idx: i64 = 0;
    free_count = 0;

    for (line, 0..) |char, i| {
        if (char == '\n') break;
        //data block
        if (@mod(i, 2) == 0) {
            const size = try std.fmt.parseInt(usize, &.{char}, 10);
            for (0..size) |_|
                try blocks.append(Block{ .id = idx, .size = size });
            idx += 1;
        }
        // free block
        else {
            const size = try std.fmt.parseInt(usize, &.{char}, 10);
            free_count += size;
            for (0..size) |_|
                try blocks.append(.{ .size = size });
        }
    }
    return try blocks.toOwnedSlice();
}

fn fmt_blocks(alloc: Allocator, blocks: []const Block) ![]u8 {
    var ret = try Array(u8).initCapacity(alloc, blocks.len);
    for (blocks) |b| {
        try ret.appendNTimes(if (b.id) |_| 'X' else '.', b.size);
    }
    return try ret.toOwnedSlice();
}

fn left_most_free(blocks: []Block, from: usize) usize {
    return blk: {
        for (from..blocks.len) |i| {
            if (blocks[i].id == null) break :blk i;
        }
        break :blk 0;
    };
}
//TODO: This needs optimized
fn right_most_block(blocks: []Block) usize {
    return blk: {
        const len = blocks.len - 1;
        var idx: usize = len;
        for (0..len) |i| {
            if (blocks[len - i].id) |_| break :blk idx;
            idx -= 1;
        }
        break :blk len;
    };
}

fn defrag(blocks: []Block) void {
    var next_free: usize = left_most_free(blocks, 0);
    var next_move: usize = right_most_block(blocks);
    while (next_free < next_move) : ({
        next_free = left_most_free(blocks, next_free);
        next_move = right_most_block(blocks);
    }) {
        // std.debug.print("Swapping {} and {}\n", .{ next_free, next_move });

        std.mem.swap(Block, &blocks[next_free], &blocks[next_move]);
    }
    // var back = blocks.len - 1;

    // std.debug.print("{}\n", .{free_count});
    // for (blocks, 0..) |b, i| {
    //     // if (i >= blocks.len - free_count) break;
    //     if (b.id == null) {
    //         blk: for (0..blocks.len - 1) |j| {
    //             const back_idx = blocks.len - 1 - j;
    //             if (blocks[back_idx].id) |_| {
    //                 // std.debug.print("Swapping {} and {}\n", .{ i, back_idx });
    //                 std.mem.swap(Block, &blocks[i], &blocks[back_idx]);
    //                 back = back_idx;
    //                 break :blk;
    //             }
    //             // if (j >= i) break;
    //         }
    //     } else continue;
    //     if (@mod(i, 10000) == 0) {
    //         for (blocks) |bl| {
    //             for (bl.size) |_|
    //                 if (bl.id) |id|
    //                     std.debug.print("[{}]", .{id})
    //                 else
    //                     std.debug.print(".", .{});
    //         }
    //         std.debug.print("\n", .{});
    //         // std.debug.print("{any}\n", .{blocks});
    //     }
    // }
}
fn checksum(blocks: []Block) i64 {
    var idx: i64 = 0;
    var ret: i64 = 0;
    for (blocks) |b| {
        if (b.id) |id| {
            ret += id * idx;
        } else continue;
        idx += 1;
    }
    return ret;
}

test {
    const b = try read_blocks(tst.allocator, test_input);
    defer tst.allocator.free(b);
    const rep = try fmt_blocks(tst.allocator, b);
    defer tst.allocator.free(rep);
    // try tst.expectEqualSlices(u8, test_representation, b);
    // std.debug.print("{}\n", .{checksum(b)});
    std.debug.print("{s}\n", .{rep});
    defrag(b);
    const rep2 = try fmt_blocks(tst.allocator, b);
    defer tst.allocator.free(rep2);
    std.debug.print("{s}\n", .{rep2});
    // try tst.expectEqualSlices(u8, test_defreg, b);
    // std.debug.print("{}\n", .{checksum(b)});
    try std.testing.expectEqual(1928, checksum(b));
}

test {
    try std.testing.expectEqual(1928, part1(test_input));
    try std.testing.expectEqual(0, part2(test_input));
}
