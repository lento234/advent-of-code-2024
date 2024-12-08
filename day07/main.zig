const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of code: day {}\n", .{7});

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

const Equation = struct {
    result: u64,
    nums: []u64,
    alloc: std.mem.Allocator,

    const Self = @This();

    pub fn init(alloc: std.mem.Allocator, line: []const u8) !Equation {
        // results
        var it = std.mem.splitScalar(u8, line, ':');
        const result = try std.fmt.parseInt(u64, it.next().?, 10);

        // numbers
        var nums = std.ArrayList(u64).init(alloc);
        var num_it = std.mem.tokenizeScalar(u8, it.rest(), ' ');
        while (num_it.next()) |n| {
            const num = try std.fmt.parseInt(u64, n, 10);
            try nums.append(num);
        }

        return Equation{
            .result = result,
            .nums = try nums.toOwnedSlice(),
            .alloc = alloc,
        };
    }

    pub fn deinit(self: Self) void {
        self.alloc.free(self.nums);
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Equation(.nums = {any}, .result = {d})", .{ self.nums, self.result });
    }
};

fn isValid(nums: []u64, result: u64, acc: u64) bool {
    if (acc > result) return false;
    if (nums.len == 0) return acc == result;
    return isValid(nums[1..], result, nums[0] + acc) or isValid(nums[1..], result, nums[0] * acc);
}

fn isValidWithConcat(nums: []u64, result: u64, acc: u64) bool {
    if (acc > result) return false;
    if (nums.len == 0) return (acc == result);

    var buf: [32]u8 = undefined;
    const num = std.fmt.parseInt(u64, std.fmt.bufPrint(&buf, "{d}{d}", .{ acc, nums[0] }) catch unreachable, 10) catch unreachable;
    return isValidWithConcat(nums[1..], result, nums[0] + acc) or isValidWithConcat(nums[1..], result, nums[0] * acc) or isValidWithConcat(nums[1..], result, num);
}

fn part1(input: []const u8) !u64 {
    // stack allocator
    var buffer: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const alloc = fba.allocator();

    // split lines
    var total: u64 = 0;
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        const eq = try Equation.init(alloc, line);
        defer eq.deinit();
        if (isValid(eq.nums[1..], eq.result, eq.nums[0])) {
            total += eq.result;
        }
    }
    return total;
}
fn part2(input: []const u8) !u64 {
    // stack allocator
    var buffer: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const alloc = fba.allocator();

    // split lines
    var total: u64 = 0;
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        const eq = try Equation.init(alloc, line);
        defer eq.deinit();
        if (isValidWithConcat(eq.nums[1..], eq.result, eq.nums[0])) {
            total += eq.result;
        }
    }
    return total;
}

test "part 1" {
    const alloc = std.testing.allocator;
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    defer alloc.free(input);
    try std.testing.expectEqual(3749, try part1(input));
}

test "part 2" {
    const alloc = std.testing.allocator;
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    defer alloc.free(input);
    try std.testing.expectEqual(11387, try part2(input));
}
