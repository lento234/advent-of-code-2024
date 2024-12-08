const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of code: day {}\n", .{8});

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

const Pos = struct {
    i: i64,
    j: i64,

    const Self = @This();

    pub fn sub(self: Self, other: Pos) Pos {
        return Pos{
            .i = self.i - other.i,
            .j = self.j - other.j,
        };
    }

    pub fn add(self: Self, other: Pos) Pos {
        return Pos{
            .i = self.i + other.i,
            .j = self.j + other.j,
        };
    }
};

const Antenna = struct {
    p: Pos,
    freq: u8,

    const Self = @This();

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Antenna(.p={{{d}, {d}}}, .freq={c})", .{ self.p.i, self.p.j, self.freq });
    }
};

const Map = struct {
    nrows: usize,
    ncols: usize,
    antennas: std.AutoArrayHashMap(Pos, Antenna),

    const Self = @This();

    pub fn init(alloc: std.mem.Allocator, input: []const u8) !Self {
        var it = std.mem.tokenizeScalar(u8, input, '\n');
        var row: usize = 0;
        var ncols: usize = undefined;

        var antennas = std.AutoArrayHashMap(Pos, Antenna).init(alloc);
        while (it.next()) |line| {
            if (row == 0) ncols = line.len;
            for (line, 0..) |c, col| {
                if (c != '.') {
                    const p = Pos{ .i = @intCast(row), .j = @intCast(col) };
                    try antennas.put(p, Antenna{ .p = p, .freq = c });
                }
            }
            row += 1;
        }

        return Map{
            .nrows = row,
            .ncols = ncols,
            .antennas = antennas,
        };
    }

    pub fn deinit(self: *Self) void {
        self.antennas.deinit();
    }

    pub fn inside(self: Self, p: Pos) bool {
        return p.i >= 0 and p.i < self.nrows and p.j >= 0 and p.j < self.ncols;
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Map: {d} x {d} ->\n", .{ self.nrows, self.ncols });
        for (0..self.nrows) |i| {
            for (0..self.ncols) |j| {
                if (self.antennas.get(Pos{ .i = @intCast(i), .j = @intCast(j) })) |a| {
                    try writer.print("{c}", .{a.freq});
                } else {
                    try writer.print(".", .{});
                }
            }
            try writer.print("\n", .{});
        }
    }
};

fn part1(alloc: std.mem.Allocator, input: []const u8) !usize {
    // std.debug.print("input:\n{s}\n", .{input});

    var map = try Map.init(alloc, input);
    defer map.deinit();
    // std.debug.print("map =\n {any}\n", .{map});

    var antinodes = std.AutoArrayHashMap(Pos, void).init(alloc);
    defer antinodes.deinit();

    for (0..map.antennas.count()) |i| {
        const a = map.antennas.values()[i];
        for (0..map.antennas.count()) |j| {
            if (i == j) continue;
            const b = map.antennas.values()[j];
            if (a.freq == b.freq) {
                const pos = b.p.add(b.p.sub(a.p));
                if (map.inside(pos)) {
                    // std.debug.print("pair({}, {}): ({}, {}) -> {any}\n", .{ i, j, a, b, pos });
                    try antinodes.put(pos, {});
                }
            }
        }
    }

    return antinodes.count();
}

fn part2(alloc: std.mem.Allocator, input: []const u8) !usize {
    // std.debug.print("input:\n{s}\n", .{input});

    var map = try Map.init(alloc, input);
    defer map.deinit();
    // std.debug.print("map =\n {any}\n", .{map});

    var antinodes = std.AutoArrayHashMap(Pos, void).init(alloc);
    defer antinodes.deinit();

    for (0..map.antennas.count()) |i| {
        const a = map.antennas.values()[i];
        for (0..map.antennas.count()) |j| {
            if (i == j) continue;
            const b = map.antennas.values()[j];
            if (a.freq == b.freq) {
                const diff = b.p.sub(a.p);
                var pos = b.p;
                while (map.inside(pos)) : (pos = pos.add(diff)) {
                    try antinodes.put(pos, {});
                }
            }
        }
    }

    return antinodes.count();
}

test "part 1" {
    const alloc = std.testing.allocator;
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    defer alloc.free(input);
    try std.testing.expectEqual(14, try part1(alloc, input));
}

test "part 2" {
    const alloc = std.testing.allocator;
    const input1 =
        \\T.........
        \\...T......
        \\.T........
        \\..........
        \\..........
        \\..........
        \\..........
        \\..........
        \\..........
        \\..........
    ;

    try std.testing.expectEqual(9, try part2(alloc, input1));

    // sample
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    defer alloc.free(input);

    try std.testing.expectEqual(34, try part2(alloc, input));
}
