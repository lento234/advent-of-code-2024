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

    const result1 = try part1(input);
    try stdout.print("Part 1: {d}\n", .{result1});

    const result2 = try part2(input);
    try stdout.print("Part 2: {d}\n", .{result2});
}

fn part1(input: []const u8) !i32 {
    // std.debug.print("input: {s}\n", .{input});

    var it = std.mem.tokenizeSequence(u8, input, "mul(");
    var total: i32 = 0;
    while (it.next()) |section| {
        // std.debug.print("secton: {s}\n", .{section});
        var nums = std.mem.tokenizeScalar(u8, section, ',');
        const l = std.fmt.parseInt(i32, nums.next().?, 10) catch continue;

        var remain = std.mem.tokenizeScalar(u8, nums.rest(), ')');
        const r = std.fmt.parseInt(i32, remain.next().?, 10) catch continue;

        // std.debug.print(" l = {d}, r = {d}\n", .{ l, r });
        total += l * r;
    }
    return total;
}

fn part2(input: []const u8) !i32 {
    // std.debug.print("input: {s}\n", .{input});

    var it = std.mem.tokenizeSequence(u8, input, "don't()");
    var total: i32 = 0;
    while (it.peek() != null) {
        const section = it.next().?;
        // std.debug.print("secton: '{s}' ", .{section});
        const n = try part1(section);
        total += n;

        it = std.mem.tokenizeSequence(u8, it.rest(), "do()");
        _ = it.next();
        // if (do) |v| std.debug.print(", do: '{s}'", .{v});

        it = std.mem.tokenizeSequence(u8, it.rest(), "don't()");

        // std.debug.print(", n = {d}, total = {d}\n", .{ n, total });
    }
    return total;
}

test "part1" {
    const input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";

    try std.testing.expectEqual(161, try part1(input));
}

test "part2" {
    const input = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";

    try std.testing.expectEqual(48, try part2(input));
}
