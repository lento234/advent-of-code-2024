const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of code: day {}\n", .{11});

    // allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // read input
    const input = try std.fs.cwd().readFileAlloc(alloc, "input.txt", 1 << 15);

    const result1 = try part1and2(alloc, input, 25);
    try stdout.print("Part 1: {d}\n", .{result1});

    const result2 = try part1and2(alloc, input, 75);
    try stdout.print("Part 2: {d}\n", .{result2});
}

const Arrangement = struct {
    const Self = @This();
    nblinks: u64,
    stones: [2]std.AutoHashMap(u64, u64),
    cidx: usize,
    alloc: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator, line: []const u8) !Self {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        // double buffer all the way
        var stones: [2]std.AutoHashMap(u64, u64) = undefined;
        for (0..2) |idx| {
            stones[idx] = std.AutoHashMap(u64, u64).init(alloc);
        }
        const cidx = 0;

        while (it.next()) |substr| {
            const status = try stones[cidx].getOrPut(try std.fmt.parseInt(u64, substr, 10));
            if (status.found_existing) {
                status.value_ptr.* += 1;
            } else {
                status.value_ptr.* = 1;
            }
        }
        return Arrangement{
            .nblinks = 0,
            .stones = stones,
            .cidx = cidx,
            .alloc = alloc,
        };
    }

    pub fn deinit(self: *Self) void {
        for (0..2) |idx| {
            self.stones[idx].deinit();
        }
    }
    pub fn print(self: Self, idx: usize) void {
        const stones = self.stones[idx];
        std.debug.print("pebbles (total={d}, idx={d}):\n", .{ self.count(), idx });
        var it = stones.iterator();
        while (it.next()) |item| {
            std.debug.print(" {d}:{d} ", .{ item.key_ptr.*, item.value_ptr.* });
        }
        std.debug.print("\n", .{});
    }

    pub fn count(self: Self) usize {
        var total: usize = 0;
        const stones = self.stones[self.cidx];
        var it = stones.valueIterator();
        while (it.next()) |n| {
            total += n.*;
        }
        return total;
    }

    pub fn blink(self: *Self) !void {
        const cidx = self.cidx;
        const nidx = (cidx + 1) % 2;
        // std.debug.print("cidx = {d}, nidx = {d}\n", .{ cidx, nidx });
        self.stones[nidx].clearRetainingCapacity();

        // add zero
        // const zeros_result = try self.stones[cidx].getOrPut("0");
        if (self.stones[cidx].get(0)) |n| {
            // std.debug.print("getting 0\n", .{});
            try self.stones[nidx].put(1, n);
            _ = self.stones[cidx].remove(0);
        }

        // update even numbers
        var it = self.stones[cidx].iterator();
        while (it.next()) |item| {
            // self.print(nidx);
            var buffer: [100]u8 = undefined;
            const number = item.key_ptr.*;
            const num_str = try std.fmt.bufPrint(&buffer, "{d}", .{number});
            if (num_str.len % 2 == 0) {
                // std.debug.print("number is even : {d}\n", .{number});
                const left = try std.fmt.parseInt(u64, num_str[0..(num_str.len / 2)], 10);
                const right = try std.fmt.parseInt(u64, num_str[(num_str.len / 2)..], 10);
                // std.debug.print("  left: {d}\n", .{left});
                // std.debug.print("  right: {d}\n", .{right});

                // left
                const left_getorput = try self.stones[nidx].getOrPut(left);
                if (left_getorput.found_existing) {
                    left_getorput.value_ptr.* += item.value_ptr.*;
                } else {
                    try self.stones[nidx].put(left, item.value_ptr.*);
                }

                //right
                const right_getorput = try self.stones[nidx].getOrPut(right);
                if (right_getorput.found_existing) {
                    right_getorput.value_ptr.* += item.value_ptr.*;
                } else {
                    try self.stones[nidx].put(right, item.value_ptr.*);
                }
            } else {
                // std.debug.print("number is odd: {d}\n", .{number});
                const new_number = number * 2024;
                const getorput = try self.stones[nidx].getOrPut(new_number);
                if (getorput.found_existing) {
                    getorput.value_ptr.* += item.value_ptr.*;
                } else {
                    try self.stones[nidx].put(new_number, item.value_ptr.*);
                }
            }
        }
        self.cidx = nidx;
    }
};

fn part1and2(alloc: std.mem.Allocator, input: []const u8, n_blinks: usize) !usize {
    const line = std.mem.trimRight(u8, input, "\n");
    // std.debug.print("line: '{s}'\n", .{line});

    var arrangement = try Arrangement.init(alloc, line);
    defer arrangement.deinit();

    // info
    // arrangement.print(arrangement.cidx);

    // blink
    for (0..n_blinks) |_| {
        try arrangement.blink();
    }

    // info
    // arrangement.print(arrangement.cidx);

    return arrangement.count();
}

test "part 1" {
    const alloc = std.testing.allocator;

    const input_1 =
        \\0 1 10 99 999
        \\
    ;

    try std.testing.expectEqual(7, try part1and2(alloc, input_1, 1));

    const input_2 =
        \\125 17
        \\
    ;

    try std.testing.expectEqual(3, try part1and2(alloc, input_2, 1));
    try std.testing.expectEqual(4, try part1and2(alloc, input_2, 2));
    try std.testing.expectEqual(5, try part1and2(alloc, input_2, 3));
    try std.testing.expectEqual(9, try part1and2(alloc, input_2, 4));
    try std.testing.expectEqual(13, try part1and2(alloc, input_2, 5));
    try std.testing.expectEqual(22, try part1and2(alloc, input_2, 6));
    try std.testing.expectEqual(55312, try part1and2(alloc, input_2, 25));
}
