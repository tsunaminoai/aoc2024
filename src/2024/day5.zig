const std = @import("std");

pub const DayNumber = 5;

pub const Answer1 = 5713;
pub const Answer2 = 5180;

pub fn part1(in: []const u8) f32 {
    var ret: i32 = 0;

    const section_split = std.mem.indexOf(u8, in, "\n\n") orelse unreachable;
    const rules_section = in[0..section_split];
    const updates_section = in[section_split + 2 ..];

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const rules = Rule.load(alloc, rules_section);
    defer rules.deinit();

    const updates = Update.load(alloc, updates_section);
    defer {
        for (updates.items) |up| up.deinit();
        updates.deinit();
    }

    const valids = valid_updates(rules.items, updates);
    _ = valids; // autofix
    ret = valid_updates_middle_page_sum(rules.items, updates);
    // std.debug.print("Found {} valid updates\nSum of middle page numbers: {}\n", .{ valids, ret });
    return @floatFromInt(ret);
}
/// The first section specifies the page ordering rules, one per line. The
/// first rule, 47|53, means that if an update includes both page number 47
/// and page number 53, then page number 47 must be printed at some point
/// before page number 53. (47 doesn't necessarily need to be immediately
/// before 53; other pages are allowed to be between them.)
const Rule = struct {
    page1: i32,
    page2: i32,
    pub fn update_obeys_rule(self: Rule, pages: []const i32) bool {
        return if (std.mem.indexOfScalar(i32, pages, self.page1)) |p1| blk: {
            if (std.mem.indexOfScalar(i32, pages, self.page2)) |p2| {
                break :blk p1 < p2;
            }
            break :blk true;
        } else true;
    }
    pub fn fix_update(self: Rule, update: *Update) void {
        var pages = update.pages.items;
        const p1 = std.mem.indexOfScalar(i32, pages, self.page1) orelse return;
        const p2 = std.mem.indexOfScalar(i32, pages, self.page2) orelse return;
        if (p1 > p2) {
            const tmp = pages[p1];
            pages[p1] = pages[p2];
            pages[p2] = tmp;
        }
    }
    pub fn fromStr(in: []const u8) Rule {
        const split = std.mem.indexOf(u8, in, "|") orelse unreachable;
        return Rule{
            .page1 = std.fmt.parseInt(i32, in[0..split], 10) catch unreachable,
            .page2 = std.fmt.parseInt(i32, in[split + 1 ..], 10) catch unreachable,
        };
    }
    pub fn load(alloc: std.mem.Allocator, in: []const u8) std.ArrayList(Rule) {
        var rules = std.ArrayList(Rule).init(alloc);
        errdefer rules.deinit();
        var line_iter = std.mem.splitScalar(u8, in, '\n');
        while (line_iter.next()) |line| {
            const rule = Rule.fromStr(line);
            rules.append(rule) catch unreachable;
        }
        return rules;
    }
};

test {
    const rule = Rule{ .page1 = 47, .page2 = 53 };
    const rule2 = Rule{ .page1 = 97, .page2 = 75 };

    try std.testing.expect(rule.update_obeys_rule(&.{ 75, 47, 61, 53, 29 }));
    try std.testing.expect(!rule2.update_obeys_rule(&.{ 75, 97, 47, 61, 53 }));

    const rules = Rule.load(std.testing.allocator, test_input[0..106]);
    defer rules.deinit();
    // std.debug.print("{any}\n", .{rules.items});
}

const Update = struct {
    pages: std.ArrayList(i32),

    pub fn init(alloc: std.mem.Allocator) Update {
        return Update{
            .pages = std.ArrayList(i32).init(alloc),
        };
    }
    pub fn deinit(self: Update) void {
        self.pages.deinit();
    }
    pub fn fromStr(self: *Update, in: []const u8) void {
        var list = std.mem.splitScalar(u8, in, ',');
        while (list.next()) |page| {
            const p = std.fmt.parseInt(i32, page, 10) catch unreachable;
            self.pages.append(p) catch unreachable;
        }
    }
    pub fn load(alloc: std.mem.Allocator, in: []const u8) std.ArrayList(Update) {
        var udpates = std.ArrayList(Update).init(alloc);
        errdefer udpates.deinit();
        var line_iter = std.mem.splitScalar(u8, in, '\n');
        while (line_iter.next()) |line| {
            var update = Update.init(alloc);
            // std.debug.print("{s}\n", .{line});
            update.fromStr(line);

            udpates.append(update) catch unreachable;
        }
        return udpates;
    }
};

test {
    const rule = Rule{ .page1 = 75, .page2 = 47 };
    const rule2 = Rule{ .page1 = 97, .page2 = 75 };
    var updates = Update.load(std.testing.allocator, section_2);
    defer {
        for (updates.items) |up| up.deinit();
        updates.deinit();
    }
    // std.debug.print("{any}\n", .{updates.items});
    var up = Update.init(std.testing.allocator);
    defer up.deinit();
    up.fromStr("75,97,47,61,53");
    rule.fix_update(&up);
    rule2.fix_update(&up);
    // std.debug.print("{any}\n", .{up.pages.items});
    try std.testing.expectEqualSlices(
        i32,
        &.{ 97, 75, 47, 61, 53 },
        up.pages.items,
    );
}

/// The second section specifies the page numbers of each update. Because most
/// safety manuals are different, the pages needed in the updates are different
/// too. The first update, 75,47,61,53,29, means that the update consists of
/// page numbers 75, 47, 61, 53, and 29.
fn valid_updates(rules: []const Rule, updates: std.ArrayList(Update)) i32 {
    var count: i32 = 0;

    for (updates.items) |update| {
        // std.debug.print("Processing update '{any}'...", .{update.pages.items});
        const pages = update.pages.items;
        rl: for (rules) |rule| {
            if (!rule.update_obeys_rule(pages)) {
                // std.debug.print("..failed on {}\n", .{rule});
                break :rl;
            }
        }
        // std.debug.print("..passed\n", .{});
        count += 1;
    }

    return count;
}
fn valid_updates_middle_page_sum(rules: []const Rule, updates: std.ArrayList(Update)) i32 {
    var sum: i32 = 0;
    up: for (updates.items) |update| {
        // std.debug.print("Processing update '{any}'...", .{update.pages.items});
        const pages = update.pages.items;

        for (rules) |rule| {
            if (!rule.update_obeys_rule(pages)) {
                // std.debug.print("..failed on {}\n", .{rule});
                continue :up;
            }
        }
        const mid_page = @divFloor(pages.len, 2);
        // std.debug.print(
        //     "..passed. Adding middle page {} at position {}\n",
        //     .{ pages[mid_page], mid_page },
        // );
        sum += pages[mid_page];
    }

    return sum;
}
fn fixed_updates_middle_page_sum(rules: []const Rule, updates: std.ArrayList(Update)) i32 {
    var sum: i32 = 0;
    for (updates.items) |*update| {
        var to_sum = false;
        // std.debug.print("Processing update '{any}'...", .{update.pages.items});
        const pages = update.pages.items;
        var fixed = false;
        while (!fixed) {
            fixed = true;
            for (rules) |rule| {
                if (!rule.update_obeys_rule(pages)) {
                    rule.fix_update(update);
                    fixed = false;
                    to_sum = true;
                }
            }
        }

        const mid_page = @divFloor(pages.len, 2);
        if (to_sum) {
            // std.debug.print(
            //     "update '{any}' was fixed and is counted\n",
            //     .{pages},
            // );
            sum += pages[mid_page];
        }
    }

    return sum;
}

pub fn part2(in: []const u8) f32 {
    var ret: i32 = 0;

    const section_split = std.mem.indexOf(u8, in, "\n\n") orelse unreachable;
    const rules_section = in[0..section_split];
    const updates_section = in[section_split + 2 ..];

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const rules = Rule.load(alloc, rules_section);
    defer rules.deinit();

    const updates = Update.load(alloc, updates_section);
    defer {
        for (updates.items) |up| up.deinit();
        updates.deinit();
    }

    const valids = valid_updates(rules.items, updates);
    _ = valids; // autofix
    ret = fixed_updates_middle_page_sum(rules.items, updates);
    // std.debug.print("Found {} valid updates\nSum of fixed middle page numbers: {}\n", .{ valids, ret });
    return @floatFromInt(ret);
}
const test_input =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
;
const section_1 =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
;
const section_2 =
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
;

test {
    try std.testing.expectEqual(143, part1(test_input));
    try std.testing.expectEqual(123, part2(test_input));
}
