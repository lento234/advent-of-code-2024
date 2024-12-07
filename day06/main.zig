const std = @import("std");

const Direction = enum(u8) {
    north = '^',
    east = '>',
    south = 'v',
    west = '<',
};

const Head = struct {
    pos: [2]usize,
    dir: Direction,
};

const Grid = struct {
    const Self = @This();
    nrows: usize,
    ncols: usize,
    head: Head,
    alloc: std.mem.Allocator,
    map: [][]u8,

    pub fn init(alloc: std.mem.Allocator, input: []const u8) !Self {
        // copy (maybe not)
        // var buffer: [10000]u8 = undefined;
        // std.mem.copyForwards(u8, &buffer, src_input);
        // const input = buffer[0..src_input.len];

        var it = std.mem.tokenizeScalar(u8, input, '\n');
        var map = std.ArrayList([]u8).init(alloc);
        defer map.deinit();
        var nrows: usize = 0;
        var ncols: usize = undefined;
        var start: [2]usize = undefined;
        while (it.next()) |line| {
            if (nrows == 0) ncols = line.len;
            if (std.mem.indexOfScalar(u8, line, '^')) |col| {
                start = .{ nrows, col };
            }
            try map.append(@constCast(line));
            nrows += 1;
        }
        var map_slice = try map.toOwnedSlice();
        map_slice[start[0]][start[1]] = 'X';
        return Self{
            .nrows = nrows,
            .ncols = ncols,
            .head = Head{ .pos = start, .dir = Direction.north },
            .alloc = alloc,
            .map = map_slice,
        };
    }

    pub fn deinit(self: Self) void {
        self.alloc.free(self.map);
    }

    pub fn get(self: Self, i: usize, j: usize) ?u8 {
        if (i >= 0 and i < self.nrows and j >= 0 and j < self.ncols)
            return self.map[i][j];
        return null;
    }

    pub fn peek(self: Self) ?u8 {
        return switch (self.head.dir) {
            .north => if (self.head.pos[0] > 0) self.get(self.head.pos[0] - 1, self.head.pos[1]) else null,
            .south => if (self.head.pos[0] < self.nrows - 1) self.get(self.head.pos[0] + 1, self.head.pos[1]) else null,
            .east => if (self.head.pos[1] < self.ncols - 1) self.get(self.head.pos[0], self.head.pos[1] + 1) else null,
            .west => if (self.head.pos[1] > 0) self.get(self.head.pos[0], self.head.pos[1] - 1) else null,
        };
    }

    pub fn turn(self: *Self) void {
        switch (self.head.dir) {
            .north => self.head.dir = .east,
            .south => self.head.dir = .west,
            .east => self.head.dir = .south,
            .west => self.head.dir = .north,
        }
    }

    pub fn walk(self: *Self) void {
        switch (self.head.dir) {
            .north => self.head.pos[0] -= 1,
            .south => self.head.pos[0] += 1,
            .east => self.head.pos[1] += 1,
            .west => self.head.pos[1] -= 1,
        }
        self.map[self.head.pos[0]][self.head.pos[1]] = 'X';
    }

    pub fn count(self: Self, char: u8) i64 {
        var total: i64 = 0;
        for (0..self.nrows) |i| {
            for (0..self.ncols) |j| {
                const c = self.get(@intCast(i), @intCast(j)).?;
                if (c == char) total += 1;
            }
        }
        return total;
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Grid({d} x {d})\n\n", .{ self.nrows, self.ncols });
        for (0..self.nrows) |i| {
            for (0..self.ncols) |j| {
                const c = if (i == self.head.pos[0] and j == self.head.pos[1])
                    @intFromEnum(self.head.dir)
                else
                    self.get(@intCast(i), @intCast(j)).?;

                if (c == '#') {
                    try writer.print("\x1b[1;34m{c}\x1b[0m", .{c});
                } else if (c == '.') {
                    try writer.print("{c}", .{c});
                } else if (c == 'X') {
                    try writer.print("\x1b[30;100m{c}\x1b[0m", .{c});
                } else {
                    try writer.print("\x1b[1;31m{c}\x1b[0m", .{c});
                }
            }
            try writer.print("\n", .{});
        }
    }
};

fn part1(alloc: std.mem.Allocator, input: []const u8) !i64 {
    var grid = try Grid.init(alloc, input);
    defer grid.deinit();

    while (grid.peek()) |c| {
        switch (c) {
            '#' => grid.turn(),
            else => grid.walk(),
        }
    }

    // std.debug.print("grid =>\n {}\n", .{grid});
    return grid.count('X');
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of code: day {}\n", .{6});

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

test "part 1" {
    const alloc = std.testing.allocator;
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    defer alloc.free(input);
    try std.testing.expectEqual(41, try part1(alloc, input));
}
