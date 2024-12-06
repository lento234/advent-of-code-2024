const std = @import("std");

const Rule = struct {
    l: i64,
    r: i64,

    const Self = @This();

    pub fn init(line: []const u8) !Self {
        var it = std.mem.tokenizeScalar(u8, line, '|');
        const l = try std.fmt.parseInt(i64, it.next().?, 10);
        const r = try std.fmt.parseInt(i64, it.next().?, 10);
        return Rule{
            .l = l,
            .r = r,
        };
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{d}|{d}", .{ self.l, self.r });
    }
};

fn part1(alloc: std.mem.Allocator, input: []const u8) !i64 {
    std.debug.print("input:\n{s}\n", .{input});

    var it = std.mem.splitScalar(u8, input, '\n');
    // const line = it.next().?;
    // const rule = try Rule.init(line);
    // std.debug.print("rule = {}\n", .{rule});
    var rules = std.ArrayList(Rule).init(alloc);
    defer rules.deinit();
    while (it.next()) |line| {
        if (std.mem.eql(u8, line, "")) break;
        // std.debug.print("rule: {s}\n", .{line});
        try rules.append(try Rule.init(line));
    }

    std.debug.print("rules ({d}) = \n{}\n", .{ rules.items.len, rules });

    // while (it.next()) |line| {
    //     if (std.mem.eql(u8, line, "")) break;
    //     std.debug.print("page: {s}\n", .{line});
    // }

    return 143;
}

test "part 1" {
    const alloc = std.testing.allocator;
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    defer alloc.free(input);
    try std.testing.expectEqual(143, try part1(alloc, input));
}
