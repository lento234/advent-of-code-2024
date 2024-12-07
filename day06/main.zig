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
    map: [][]const u8,

    pub fn init(alloc: std.mem.Allocator, input: []const u8) !Self {
        var it = std.mem.tokenizeScalar(u8, input, '\n');
        var map = std.ArrayList([]const u8).init(alloc);
        defer map.deinit();
        var nrows: usize = 0;
        var ncols: usize = undefined;
        var start: [2]usize = undefined;
        while (it.next()) |line| {
            if (nrows == 0) ncols = line.len;
            if (std.mem.indexOfScalar(u8, line, '^')) |col| {
                // start = .{ nrows, col };
                _ = col;
                start = .{ 0, 0 };
            }
            try map.append(line);
            nrows += 1;
        }
        return Self{
            .nrows = nrows,
            .ncols = ncols,
            .head = Head{ .pos = start, .dir = Direction.north },
            .alloc = alloc,
            .map = try map.toOwnedSlice(),
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

    pub fn peek(self: Self) !void {
        return switch (self.head.dir) {
            .north => if (self.head.pos[0] > 0) [2]usize{ self.head.pos[0] - 1, self.head.pos[1] } else null,
            .south => if (self.head.pos[0] < self.nrows - 1) [2]usize{ self.head.pos[0] + 1, self.head.pos[1] } else null,
            .east => if (self.head.pos[1] < self.ncols - 1) [2]usize{ self.head.pos[0], self.head.pos[1] + 1 } else null,
            .west => if (self.head.pos[1] > 0) [2]usize{ self.head.pos[0], self.head.pos[1] - 1 } else null,
        };
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Grid({d} x {d})\n\n", .{ self.nrows, self.ncols });
        var start: [2]usize = undefined;
        for (0..self.nrows) |i| {
            for (0..self.ncols) |j| {
                const c = self.get(@intCast(i), @intCast(j)).?;
                if (c == '#') {
                    try writer.print("\x1b[1;31m{c}\x1b[0m", .{c});
                } else if (c == @intFromEnum(Direction.north)) {
                    try writer.print("\x1b[31;43m{c}\x1b[0m", .{c});
                    start = .{ i, j };
                } else {
                    try writer.print("{c}", .{c});
                }
            }
            try writer.print("\n", .{});
        }
        try writer.print("head = {any}\n", .{self.head});
    }
};

fn part1(alloc: std.mem.Allocator, input: []const u8) !void {
    const grid = try Grid.init(alloc, input);
    defer grid.deinit();

    std.debug.print("initial\n:{?}\n", .{grid});

    grid.peek();
    // std.debug.print("next = {}\n", .{next});
}

test "part 1" {
    const alloc = std.testing.allocator;
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    defer alloc.free(input);

    std.debug.print("input = \n{s}\n", .{input});
    try part1(alloc, input);
}
