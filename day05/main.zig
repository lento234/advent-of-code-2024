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

    const result2 = try part2(alloc, input);
    try stdout.print("Part 2: {d}\n", .{result2});
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
    // iterator
    var it = std.mem.splitScalar(u8, input, '\n');

    // parse rules
    var rules = std.StringArrayHashMap(void).init(alloc);
    defer rules.deinit();
    while (it.next()) |line| {
        if (std.mem.eql(u8, line, "")) break;
        try rules.put(line, {});
    }
    // std.debug.print("rules ({d}) = \n{s}\n", .{ rules.count(), rules.keys() });

    var total: i64 = 0;

    var buf = try std.ArrayList(u8).initCapacity(alloc, 5);
    defer buf.deinit();
    var writer = buf.writer();

    outer: while (it.next()) |line| {
        if (std.mem.eql(u8, line, "")) break;
        const nums = try stringToNumbers(alloc, line, ',');
        defer alloc.free(nums);
        // std.debug.print("page: {s} ->\n", .{line});
        for (0..(nums.len - 1)) |i| {
            for ((i + 1)..(nums.len)) |j| {
                try writer.print("{d}|{d}", .{ nums[j], nums[i] });
                defer buf.clearRetainingCapacity();
                if (rules.contains(buf.items)) continue :outer;
            }
        }
        total += nums[nums.len / 2];
    }

    return total;
}

fn isValid(nums: []i64, rules: std.StringArrayHashMap(void)) !bool {
    var buf: [5]u8 = undefined;
    for (0..(nums.len - 1)) |i| {
        for ((i + 1)..(nums.len)) |j| {
            const key = try std.fmt.bufPrint(&buf, "{d}|{d}", .{ nums[j], nums[i] });
            if (rules.contains(key)) return false;
        }
    }
    return true;
}

fn reorder(nums: []i64, rules: std.StringArrayHashMap(void)) !void {
    var buf: [5]u8 = undefined;
    for (0..(nums.len - 1)) |ii| {
        const i = nums.len - ii - 1;
        for ((ii + 1)..(nums.len)) |jj| {
            const j = nums.len - jj - 1;
            const key = try std.fmt.bufPrint(&buf, "{d}|{d}", .{ nums[j], nums[i] });
            if (!rules.contains(key)) {
                std.mem.swap(i64, &nums[j], &nums[i]);
            }
        }
    }
}

fn part2(alloc: std.mem.Allocator, input: []const u8) !i64 {
    var it = std.mem.splitScalar(u8, input, '\n');
    var rules = std.StringArrayHashMap(void).init(alloc);
    defer rules.deinit();
    while (it.next()) |line| {
        if (std.mem.eql(u8, line, "")) break;
        try rules.put(line, {});
    }

    var total: i64 = 0;

    while (it.next()) |line| {
        if (std.mem.eql(u8, line, "")) break;
        const nums: []i64 = try stringToNumbers(alloc, line, ',');
        defer alloc.free(nums);
        if (!try isValid(nums, rules)) {
            try reorder(nums, rules);
            total += nums[nums.len / 2];
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

test "part 2" {
    const alloc = std.testing.allocator;
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    defer alloc.free(input);
    try std.testing.expectEqual(123, try part2(alloc, input));
}
