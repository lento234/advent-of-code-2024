const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of code: day {}\n", .{2});

    // allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // read input
    const input = try std.fs.cwd().readFileAlloc(alloc, "input.txt", 1 << 15);

    const result1 = try part1(alloc, input);
    try stdout.print("Part 1: {d}\n", .{result1});
}

fn arrayFromStr(line: []const u8, arr: *std.ArrayList(i32)) !void {
    var splits = std.mem.tokenizeScalar(u8, line, ' ');
    while (splits.next()) |s| {
        try arr.append(try std.fmt.parseInt(i32, s, 10));
    }
}

fn isSafe(arr: []const i32) bool {
    const increasing = arr[arr.len - 1] > arr[0];

    for (arr[0..(arr.len - 1)], arr[1..]) |l, r| {
        const diff = r - l;
        if (diff == 0 or (increasing and diff < 0) or (!increasing and diff > 0) or @abs(diff) > 3) {
            return false;
        }
    }

    return true;
}

fn part1(alloc: std.mem.Allocator, input: []const u8) !i32 {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var answer: i32 = 0;
    var i: u32 = 0;
    while (lines.next()) |line| : (i += 1) {
        var list = std.ArrayList(i32).init(alloc);
        defer list.deinit();

        try arrayFromStr(line, &list);
        if (isSafe(list.items)) {
            answer += 1;
            std.debug.print("line [{d:04}]-> '{s}' [safe]\n", .{ i, line });
        } else {
            std.debug.print("line [{d:04}]-> '{s}' [not safe]\n", .{ i, line });
        }
    }
    return answer;
}

test "part 1" {
    const input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;
    const alloc = std.testing.allocator;

    try std.testing.expectEqual(2, try part1(alloc, input));
}
