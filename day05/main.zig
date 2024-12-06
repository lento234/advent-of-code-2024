const std = @import("std");
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of code: day {}\n", .{4});

    // allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // read input
    const input = try std.fs.cwd().readFileAlloc(alloc, "input.txt", 1 << 15);

    const result1 = try part1(alloc, input);
    try stdout.print("Part 1: {d}\n", .{result1});

    // const result2 = try part2(alloc, input);
    // try stdout.print("Part 2: {d}\n", .{result2});
}

fn stringToNumbers(alloc: std.mem.Allocator, line: []const u8, delimiter: u8) ![]i64 {
    var it = std.mem.tokenizeScalar(u8, line, delimiter);
    var arr = std.ArrayList(i64).init(alloc);
    while (it.next()) |value| {
        try arr.append(try std.fmt.parseInt(i64, value, 10));
    }
    return arr.toOwnedSlice();
}

fn part1(alloc: std.mem.Allocator, input: []const u8) !i64 {
    std.debug.print("input:\n{s}\n", .{input});

    var it = std.mem.splitScalar(u8, input, '\n');
    // const line = it.next().?;
    // const rule = try Rule.init(line);
    // std.debug.print("rule = {}\n", .{rule});
    var rules = std.StringArrayHashMap(void).init(alloc);
    defer rules.deinit();
    while (it.next()) |line| {
        if (std.mem.eql(u8, line, "")) break;
        // std.debug.print("rule: {s}\n", .{line});
        try rules.put(line, {});
        // append(try Rule.init(line));
    }

    std.debug.print("rules ({d}) = \n{s}\n", .{ rules.count(), rules.keys() });

    var buf = try std.ArrayList(u8).initCapacity(alloc, 5);
    defer buf.deinit();
    var writer = buf.writer();
    var total: i64 = 0;
    while (it.next()) |line| {
        if (std.mem.eql(u8, line, "")) break;
        const nums = try stringToNumbers(alloc, line, ',');
        defer alloc.free(nums);
        // std.debug.print("page: {s} ->\n", .{line});
        var inside: bool = undefined;
        outer: for (0..(nums.len - 1)) |i| {
            for ((i + 1)..(nums.len)) |j| {
                try writer.print("{d}|{d}", .{ nums[j], nums[i] });
                defer buf.clearRetainingCapacity();
                inside = rules.contains(buf.items);
                // std.debug.print("  '{s}' ({})\n", .{ buf.items, inside });
                if (inside) break :outer;
            }
        }
        if (inside) {
            std.debug.print("page: {s} (BAD)\n", .{line});
        } else {
            const value = nums[nums.len / 2];
            std.debug.print("page: {s} (GOOD) {d}\n", .{ line, value });
            total += value;
        }
    }

    return total;
}

test "part 1" {
    const alloc = std.testing.allocator;
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    defer alloc.free(input);
    try std.testing.expectEqual(143, try part1(alloc, input));
}
