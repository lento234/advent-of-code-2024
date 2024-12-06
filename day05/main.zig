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

fn isValid(alloc: std.mem.Allocator, nums: []i64, rules: std.StringArrayHashMap(void)) !bool {
    var buf = try std.ArrayList(u8).initCapacity(alloc, 5);
    defer buf.deinit();
    var writer = buf.writer();
    for (0..(nums.len - 1)) |i| {
        for ((i + 1)..(nums.len)) |j| {
            try writer.print("{d}|{d}", .{ nums[j], nums[i] });
            defer buf.clearRetainingCapacity();
            if (rules.contains(buf.items)) return false;
        }
    }
    return true;
}

fn part2(alloc: std.mem.Allocator, input: []const u8) !i64 {
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

    while (it.next()) |line| {
        if (std.mem.eql(u8, line, "")) break;
        const nums: []i64 = try stringToNumbers(alloc, line, ',');
        defer alloc.free(nums);
        if (!try isValid(alloc, nums, rules)) {
            std.debug.print("{any} ", .{nums});
            std.mem.sort(i64, nums, {}, comptime std.sort.asc(i64));
            std.debug.print(", sorted = {any}\n", .{nums});
        }
    }

    return 123;
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
