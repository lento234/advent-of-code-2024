const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of code: day {}\n", .{1});

    // allocaor
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // parse input
    const data = try std.fs.cwd().readFileAlloc(alloc, "input.txt", 1 << 14);

    // Part 1
    const result1 = try part1(u32, alloc, data);
    try stdout.print("Part 1: {}\n", .{result1});

    // Part 2
    const result2 = try part2(u32, alloc, data);
    try stdout.print("Part 2: {}\n", .{result2});
}

pub fn part1(comptime T: type, alloc: std.mem.Allocator, input: []const u8) !u32 {
    // std.debug.print("part 1\n", .{});
    // std.debug.print("input:\n", .{});

    var lhs = std.ArrayList(T).init(alloc);
    defer lhs.deinit();
    var rhs = std.ArrayList(T).init(alloc);
    defer rhs.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        // std.debug.print("line [{d:04}]: {s}\n", .{ k, line });
        var splits = std.mem.tokenizeAny(u8, line, " ");
        const a = std.mem.sliceTo(splits.next().?, ' ');
        try lhs.append(try std.fmt.parseInt(T, a, 10));
        const b = std.mem.sliceTo(splits.next().?, ' ');
        try rhs.append(try std.fmt.parseInt(T, b, 10));
    }

    // sort
    std.mem.sort(T, lhs.items, {}, comptime std.sort.asc(T));
    std.mem.sort(T, rhs.items, {}, comptime std.sort.asc(T));

    var dist: T = 0;
    for (lhs.items, rhs.items) |l, r| {
        // std.debug.print("{d:04}: {d} {d}\n", .{ i, l, r });
        dist += if (r < l) l - r else r - l;
    }
    // std.debug.print("answer = {d}\n", .{dist});

    return dist;
}

pub fn part2(comptime T: type, alloc: std.mem.Allocator, input: []const u8) !u32 {
    var lhs = std.ArrayList(T).init(alloc);
    defer lhs.deinit();
    var rhs = std.AutoHashMap(T, T).init(alloc);
    defer rhs.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        // std.debug.print("line [{d:04}]: {s}\n", .{ k, line });
        var splits = std.mem.tokenizeAny(u8, line, " ");
        const a_slice = std.mem.sliceTo(splits.next().?, ' ');
        const a = try std.fmt.parseInt(T, a_slice, 10);
        try lhs.append(a);

        const b_slice = std.mem.sliceTo(splits.next().?, ' ');
        const b = try std.fmt.parseInt(T, b_slice, 10);

        try rhs.put(b, if (rhs.get(b)) |v| v + 1 else 1);
    }

    var score: u32 = 0;
    for (lhs.items) |item| {
        const count = if (rhs.get(item)) |v| v else 0;
        // std.debug.print("[{d:04}]: {}, {}\n", .{ i, item, count });
        score += item * count;
    }

    // std.debug.print("score = {}\n", .{score});

    return score;
}

test "part 1" {
    const input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;

    const alloc = std.testing.allocator;

    try std.testing.expectEqual(try part1(u32, alloc, input), 11);
}

test "part 2" {
    const input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;

    const alloc = std.testing.allocator;

    try std.testing.expectEqual(try part2(u32, alloc, input), 31);
}
