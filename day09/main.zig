const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of code: day {}\n", .{9});

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

fn part1(alloc: std.mem.Allocator, input: []const u8) !u64 {
    // std.debug.print("input:\n'{s}' ({d})\n", .{ input, input.len });

    // strip newline
    const line = std.mem.trimRight(u8, input, "\n");
    // std.debug.print("line:\n'{s}' ({d})\n", .{ line, line.len });

    // allocate space
    var disk = try std.ArrayList(u16).initCapacity(alloc, line.len * 9);
    defer disk.deinit();

    // create disk map
    var k: u16 = 0;
    for (line, 0..) |c, i| {
        const n = c - '0';
        if ((i + 1) % 2 == 0)
            k += 1;
        const v = if (i % 2 == 0) k + '0' else '.';
        for (0..n) |_| {
            try disk.append(v);
        }
    }

    // std.debug.print("disk => '{u}'\n", .{disk.items});
    //
    // defragment
    var i: usize = 0;
    var j: usize = disk.items.len - 1;
    while (i < j) : (i += 1) {
        if (disk.items[i] == '.') {
            std.mem.swap(u16, &disk.items[i], &disk.items[j]);
            while (disk.items[j] == '.') : (j -= 1) {}
        }
    }

    // std.debug.print("disk => '{u}' ({d})\n", .{ disk.items, i });

    // calculate checksum
    var total: u64 = 0;
    var idx: usize = 0;
    while (disk.items[idx] != '.') : (idx += 1) {
        total += idx * (disk.items[idx] - '0');
    }
    // std.debug.print("total: {d}\n", .{total});
    return total;
}

const File = struct {
    id: u16,
    size: u8,

    pub fn format(self: File, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("File(.id='{u}', .size={d})", .{ self.id, self.size });
    }
};

fn part2(alloc: std.mem.Allocator, input: []const u8) !usize {
    // strip newline
    const line = std.mem.trimRight(u8, input, "\n");

    // allocate space
    var disk = try std.ArrayList(File).initCapacity(alloc, line.len);
    defer disk.deinit();

    // create disk map
    var k: u16 = 0;
    for (line, 0..) |c, i| {
        const n = c - '0';
        if ((i + 1) % 2 == 0)
            k += 1;
        if (n > 0) {
            try disk.append(File{
                .id = if (i % 2 == 0) k + '0' else '.',
                .size = n,
            });
        }
    }

    // fragment
    var j: usize = disk.items.len - 1;
    while (j > 0) : (j -= 1) {
        if (disk.items[j].id == '.') continue;
        const target_size = disk.items[j].size;
        var i: usize = 0;
        while (i < j) : (i += 1) {
            if (disk.items[i].id == '.' and disk.items[i].size >= target_size) {
                // std.debug.print("j={d}, i={d}, target-size={d}, size={d}, id='{u}'\n", .{ j, i, target_size, disk.items[i].size, disk.items[j].id });
                if (disk.items[i].size == target_size) {
                    std.mem.swap(File, &disk.items[i], &disk.items[j]);
                } else {
                    const r = disk.orderedRemove(j);
                    try disk.insert(i, r);
                    disk.items[i + 1].size -= disk.items[i].size;
                    try disk.insert(j + 1, File{ .id = '.', .size = r.size });
                    j += 1;
                }
                break;
            }
        }
    }

    var total: usize = 0;
    var idx: usize = 0;
    for (disk.items) |d| {
        for (0..d.size) |_| {
            if (d.id != '.')
                total += idx * (d.id - '0');
            idx += 1;
        }
    }
    return total;
}

test "part 1" {
    const alloc = std.testing.allocator;
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    defer alloc.free(input);

    try std.testing.expectEqual(1928, try part1(alloc, input));
}

test "part 2" {
    const alloc = std.testing.allocator;
    // const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    // defer alloc.free(input);
    const input_a = "1011";

    try std.testing.expectEqual(1, try part2(alloc, input_a));

    const input_b = "2333133121414131402";

    try std.testing.expectEqual(2858, try part2(alloc, input_b));
}
