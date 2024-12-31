const std = @import("std");
const Array = std.ArrayList;
const Allocator = std.mem.Allocator;
const tst = std.testing;
const math = std.math;
const posix = std.posix;
const json = std.json;
const rem = @import("rem");

pub const User = struct {
    token: []u8,
    owner: []u8 = undefined,
    allocator: Allocator,

    const default_owner = "unknown.unknown.0";

    pub fn init(alloc: Allocator, token: ?[]const u8) !*User {
        const user = try alloc.create(User);
        errdefer alloc.destroy(user);

        user.allocator = alloc;

        if (token) |t| {
            user.token = try alloc.alloc(u8, t.len);
            @memcpy(user.token, t);
        }

        return user;
    }
    pub fn deinit(self: *User) void {
        self.allocator.free(self.token);
        self.allocator.destroy(self);
    }
    pub fn discover(alloc: Allocator) !*User {
        if (posix.getenv("AOC_SESSION")) |cookie|
            return try User.init(alloc, cookie);

        return error.NoTokenSpecified;
    }
};

test {
    var user = try User.discover(tst.allocator);
    defer user.deinit();
    std.debug.print("{s}\n", .{user.token});
}

pub const Puzzle = struct {
    year: u16,
    day: u16,
    user: *User = undefined,
    input_data_url: []const u8 = undefined,
    submit_url: []const u8 = undefined,
    allocator: Allocator,

    pub fn init(
        alloc: Allocator,
        day: u16,
        year: u16,
    ) Puzzle {
        return .{
            .allocator = alloc,
            .day = day,
            .year = year,
        };
    }

    pub fn input_data(self: Puzzle) []const u8 {
        _ = self; // autofix
    }
    pub const Example = struct {
        input_data: []const u8,
        answer_a: []const u8,
        answer_b: []const u8,
        extra: ?*anyopaque,
    };
    pub fn examples(self: Puzzle) []Example {
        _ = self; // autofix
    }

    pub fn fetch_html(
        self: *Puzzle,
        url: []const u8,
    ) !void {
        const headers_max_size = 1024 * 4;
        const body_max_size = 65536 * 4;

        var client = std.http.Client{ .allocator = self.allocator };
        defer client.deinit();

        var hbuffer: [headers_max_size]u8 = undefined;
        const options = std.http.Client.RequestOptions{ .server_header_buffer = &hbuffer };

        const uri = try std.Uri.parse(url);

        // Call the API endpoint
        var request = try client.open(std.http.Method.GET, uri, options);
        defer request.deinit();
        _ = try request.send();
        _ = try request.finish();
        _ = try request.wait();

        // Check the HTTP return code
        if (request.response.status != std.http.Status.ok) {
            return error.WrongStatusResponse;
        }

        // Read the body
        var bbuffer: [body_max_size]u8 = undefined;
        const hlength = request.response.parser.header_bytes_len;
        _ = hlength; // autofix
        const blen = try request.readAll(&bbuffer);
        // const blength = request.response.content_length orelse return error.NoBodyLength; // We trust
        // the Content-Length returned by the server…

        // Display the result
        // std.debug.print("{d} header bytes returned:\n{s}\n", .{ hlength, hbuffer[0..hlength] });
        // The response is in JSON so we should here add JSON parsing code.
        // std.debug.print("{d} body bytes returned:\n{s}\n", .{ blen, bbuffer[0..blen] });

        var dom = rem.Dom{ .allocator = self.allocator };
        defer dom.deinit();
        var utf8 = (try std.unicode.Utf8View.init(bbuffer[0..blen])).iterator();

        var str = Array(u21).init(self.allocator);
        defer str.deinit();
        while (utf8.nextCodepoint()) |cp|
            try str.append(cp);

        var parser = try rem.Parser.init(
            &dom,
            str.items,
            self.allocator,
            .report,
            false,
        );
        defer parser.deinit();

        try parser.run();

        const errors = parser.errors();
        for (errors) |e|
            std.debug.print("{any}\n", .{e});
        // std.debug.assert(errors.len == 0);

        const doc = parser.getDocument();

        std.debug.print("{any}\n", .{doc.element});
    }
    pub fn parse(self: *Puzzle) !void {

        // This is the text that will be read by the parser.
        // Since the parser accepts Unicode codepoints, the text must be decoded before it can be used.
        const input = "<!doctype html><html><h1 style=bold>Your text goes here!</h1>";
        const decoded_input = &rem.util.utf8DecodeStringComptime(input);

        // Create the DOM in which the parsed Document will be created.
        var dom = rem.Dom{
            .allocator = self.allocator,
        };
        defer dom.deinit();

        // Create the HTML parser.
        var parser = try rem.Parser.init(
            &dom,
            decoded_input,
            self.allocator,
            .report,
            false,
        );
        defer parser.deinit();

        // This causes the parser to read the input and produce a Document.
        try parser.run();

        // `errors` returns the list of parse errors that were encountered while parsing.
        // Since we know that our input was well-formed HTML, we expect there to be 0 parse errors.
        const errors = parser.errors();
        std.debug.assert(errors.len == 0);

        // We can now print the resulting Document to the console.
        const stdout = std.io.getStdOut().writer();
        const document = parser.getDocument();
        try rem.util.printDocument(
            stdout,
            document,
            &dom,
            self.allocator,
        );
    }
};

test {
    var p = Puzzle{
        .allocator = tst.allocator,
        .day = 19,
        .year = 2024,
    };
    try p.fetch_html("https://falseblue.com");
}
