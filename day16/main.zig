const std = @import("std");

const Dir = enum { east, west, north, south };

const Pos = struct {
    const Self = @This();
    i: usize,
    j: usize,

    pub fn init(k: usize, ncols: usize) Pos {
        return Pos{ .i = @divFloor(k, ncols), .j = @mod(k, ncols) };
    }

    pub fn toIdx(self: Self, ncols: usize) usize {
        return self.j + self.i * ncols;
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("({d}, {d})", .{ self.i, self.j });
    }
};

const Reindeer = struct { p: Pos, d: Dir };

const Grid = struct {
    const Self = @This();
    nrows: usize,
    ncols: usize,
    map: []const u8,
    start: Pos,
    end: Pos,

    pub fn init(input: []const u8) !Grid {
        var it = std.mem.tokenizeScalar(u8, input, '\n');
        const line = it.next().?;
        const ncols = line.len + 1;
        const nrows = try std.math.divExact(usize, input.len, ncols);

        const k_S = std.mem.indexOfScalarPos(u8, input, 0, 'S').?;
        const k_E = std.mem.indexOfScalarPos(u8, input, 0, 'E').?;
        return Grid{
            .nrows = nrows,
            .ncols = ncols,
            .map = input,
            .start = Pos.init(k_S, ncols),
            .end = Pos.init(k_E, ncols),
        };
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Grid {d} x {d} [start = {}, end = {}]:\n\n", .{ self.nrows, self.ncols, self.start, self.end });

        for (0..self.nrows) |i| {
            try writer.print(" ", .{});
            for (0..(self.ncols - 1)) |j| { // skip newline
                const k = j + i * self.ncols;
                try writer.print("{c}", .{self.map[k]});
            }
            try writer.print("\n", .{});
        }
    }
};

fn part1(input: []const u8) !void {
    std.debug.print("input:\n{s}\n", .{input});

    // var buffer: [1 << 20]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const alloc = fba.allocator();

    const grid = try Grid.init(input);

    std.debug.print("{}\n", .{grid});
}

test "part 1" {
    const input =
        \\###############
        \\#.......#....E#
        \\#.#.###.#.###.#
        \\#.....#.#...#.#
        \\#.###.#####.#.#
        \\#.#.#.......#.#
        \\#.#.#####.###.#
        \\#...........#.#
        \\###.#.#####.#.#
        \\#...#.....#.#.#
        \\#.#.#.###.#.#.#
        \\#.....#...#.#.#
        \\#.###.#.#.#.#.#
        \\#S..#.....#...#
        \\###############
        \\
    ;

    try part1(input);
}
