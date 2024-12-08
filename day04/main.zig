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

const Point = struct {
    i: i64,
    j: i64,

    const Self = @This();

    pub fn add(self: Self, other: Point) Point {
        return Point{
            .i = self.i + other.i,
            .j = self.j + other.j,
        };
    }
    pub fn mul(self: Self, s: i64) Point {
        return Point{
            .i = self.i * s,
            .j = self.j * s,
        };
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("({d}, {d})", .{ self.i, self.j });
    }
};
// const Dir = Point;

const Grid = struct {
    alloc: std.mem.Allocator,
    nrows: usize,
    ncols: usize,
    data: [][]const u8,

    const Self = @This();

    pub fn init(alloc: std.mem.Allocator, input: []const u8) !Self {
        var splits = std.mem.tokenizeScalar(u8, input, '\n');

        var ncols: usize = undefined;
        var nrows: usize = undefined;
        var i: usize = 0;

        var list = std.ArrayList([]const u8).init(alloc);
        defer list.deinit();
        while (splits.next()) |line| {
            if (i == 0)
                ncols = line.len;
            try list.append(line);
            i += 1;
        }
        nrows = i;
        const slice = try list.toOwnedSlice();
        return Grid{
            .alloc = alloc,
            .ncols = ncols,
            .nrows = nrows,
            .data = slice,
        };
    }

    pub fn inside(self: Self, p: Point) bool {
        if (p.i >= 0 and p.i < self.nrows and p.j >= 0 and p.j < self.ncols)
            return true;
        return false;
    }

    pub fn deinit(self: Self) void {
        self.alloc.free(self.data);
    }

    pub fn get(self: Self, p: Point) u8 {
        // if (self.inside(i, j))
        return self.data[@intCast(p.i)][@intCast(p.j)];
        // return null;
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Grid({d} x {d})\n\n", .{ self.nrows, self.ncols });
        for (0..self.nrows) |i| {
            for (0..self.ncols) |j| {
                const c = self.get(Point{ .i = @intCast(i), .j = @intCast(j) });
                if (c == 'X') {
                    try writer.print("\x1b[93;41m{c}\x1b[0m", .{c});
                } else {
                    try writer.print("{c}", .{c});
                }
            }
            try writer.print("\n", .{});
        }
    }
};

fn part1(alloc: std.mem.Allocator, input: []const u8) !i64 {
    // std.debug.print("input:\n{s}\n", .{input});

    // const grid = Grid{ .nrows = 1, .ncols = 1 };
    const grid = try Grid.init(alloc, input);
    defer grid.deinit();

    // std.debug.print("grid:\n{?}\n", .{grid});

    const dir = [_]Point{
        .{ .i = 0, .j = 1 }, // right
        .{ .i = 0, .j = -1 }, // left
        .{ .i = 1, .j = 0 }, // bottom
        .{ .i = -1, .j = 0 }, // top
        .{ .i = 1, .j = -1 }, // bottom-left
        .{ .i = 1, .j = 1 }, // bottom-right
        .{ .i = -1, .j = -1 }, // top-left
        .{ .i = -1, .j = 1 }, // top-right
    };

    var total: i64 = 0;
    for (0..grid.nrows) |i| {
        for (0..grid.ncols) |j| {
            const start = Point{ .i = @intCast(i), .j = @intCast(j) };
            if (grid.get(start) != 'X') continue;

            for (dir) |d| {
                const p1 = start.add(d.mul(1));
                const p2 = start.add(d.mul(2));
                const p3 = start.add(d.mul(3));
                if (grid.inside(p1) and grid.inside(p2) and grid.inside(p3) and grid.get(p1) == 'M' and grid.get(p2) == 'A' and grid.get(p3) == 'S') {
                    // std.debug.print(" d = {}, X{c}{c}{c}\n", .{ d, grid.get(p1), grid.get(p2), grid.get(p3) });
                    total += 1;
                }
            }
        }
    }
    return total;
}

fn part2(alloc: std.mem.Allocator, input: []const u8) !i64 {
    // std.debug.print("input:\n{s}\n", .{input});

    // const grid = Grid{ .nrows = 1, .ncols = 1 };
    const grid = try Grid.init(alloc, input);
    defer grid.deinit();

    // std.debug.print("grid:\n{?}\n", .{grid});

    const dbl = Point{ .i = 1, .j = -1 }; // bottom-left
    const dbr = Point{ .i = 1, .j = 1 }; // bottom-right
    const dtl = Point{ .i = -1, .j = -1 }; // top-left
    const dtr = Point{ .i = -1, .j = 1 }; // top-right

    var total: i64 = 0;
    for (0..grid.nrows) |i| {
        for (0..grid.ncols) |j| {
            const start = Point{ .i = @intCast(i), .j = @intCast(j) };
            if (grid.get(start) != 'A') continue;

            const bl = start.add(dbl);
            const br = start.add(dbr);
            const tl = start.add(dtl);
            const tr = start.add(dtr);

            if (!grid.inside(bl) or !grid.inside(br) or !grid.inside(tl) or !grid.inside(tr)) continue;

            if (((grid.get(bl) == 'M' and grid.get(tr) == 'S') or
                (grid.get(bl) == 'S' and grid.get(tr) == 'M')) and ((grid.get(tl) == 'M' and grid.get(br) == 'S') or
                (grid.get(tl) == 'S' and grid.get(br) == 'M')))
            {
                // std.debug.print(" {}, {c}\n", .{ start, grid.get(start) });
                total += 1;
            }
        }
    }

    return total;
}

test "part 1" {
    const alloc = std.testing.allocator;
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    defer alloc.free(input);
    try std.testing.expectEqual(18, try part1(alloc, input));
}

test "part 2" {
    const alloc = std.testing.allocator;
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    defer alloc.free(input);
    try std.testing.expectEqual(9, try part2(alloc, input));
}
