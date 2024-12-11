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

const Point = struct {
    i: i64,
    j: i64,

    const Self = @This();

    fn add(self: Self, other: Point) Point {
        return Point{ .i = self.i + other.i, .j = self.j + other.j };
    }
};

const Grid = struct {
    nrows: usize,
    ncols: usize,
    field: [][]i8,
    alloc: std.mem.Allocator,

    const Self = @This();

    fn init(alloc: std.mem.Allocator, input: []const u8) !Grid {
        var it = std.mem.tokenizeScalar(u8, input, '\n');

        var ncols: usize = 0;
        var row: usize = 0;
        var field = std.ArrayList([]i8).init(alloc);
        while (it.next()) |line| : (row += 1) {
            if (row == 0) ncols = line.len;
            var tmp = try std.ArrayList(i8).initCapacity(alloc, line.len);
            for (line) |c| {
                try tmp.append(@intCast(c - '0'));
            }
            try field.append(try tmp.toOwnedSlice());
        }

        return Grid{
            .nrows = row,
            .ncols = ncols,
            .field = try field.toOwnedSlice(),
            .alloc = alloc,
        };
    }

    fn deinit(self: Self) void {
        for (self.field) |f| {
            self.alloc.free(f);
        }
        self.alloc.free(self.field);
    }

    fn inside(self: Self, p: Point) bool {
        return p.i >= 0 and p.i < self.nrows and p.j >= 0 and p.j < self.ncols;
    }

    fn get(self: Self, p: Point) i8 {
        return self.field[@intCast(p.i)][@intCast(p.j)];
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Grid ({d} x {d}):\n\n", .{ self.nrows, self.ncols });
        for (0..self.nrows) |i| {
            try writer.print("  ", .{});
            for (0..self.ncols) |j| {
                const f = self.field[i][j];
                if (f == 0) {
                    try writer.print("\x1b[93;34m{d}\x1b[0m", .{f});
                } else if (f == 9) {
                    try writer.print("\x1b[93;31m{d}\x1b[0m", .{f});
                } else {
                    try writer.print("{d}", .{f});
                }
            }
            try writer.print("\n", .{});
        }
    }
};

fn part1(alloc: std.mem.Allocator, input: []const u8) !usize {
    // var buffer: [1 << 16]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const alloc = fba.allocator();

    const grid = try Grid.init(alloc, input);
    defer grid.deinit();

    // print grid
    // std.debug.print("{}\n", .{grid});

    const neighbors = [_]Point{
        Point{ .i = -1, .j = 0 },
        Point{ .i = 1, .j = 0 },
        Point{ .i = 0, .j = 1 },
        Point{ .i = 0, .j = -1 },
    };

    var total_reaches = std.AutoArrayHashMap(Point, void).init(alloc);
    defer total_reaches.deinit();
    var stack = try std.ArrayList(Point).initCapacity(alloc, grid.nrows * grid.ncols);
    defer stack.deinit();

    var total: usize = 0;
    for (0..grid.nrows) |i| {
        for (0..grid.ncols) |j| {
            if (grid.field[i][j] != 0) continue;

            // depth-first-search
            defer total_reaches.clearRetainingCapacity();
            defer stack.clearRetainingCapacity();
            try stack.append(Point{ .i = @intCast(i), .j = @intCast(j) });
            while (stack.popOrNull()) |p| {
                if (grid.get(p) == 9) {
                    // std.debug.print("reach 9 at {any}\n", .{p});
                    try total_reaches.put(p, {});
                    continue;
                    // break;
                }

                for (neighbors) |dp| {
                    const n = p.add(dp);
                    // std.debug.print("{any} + {any} -> {any} ({})\n", .{ p, dp, n, grid.inside(n) });
                    if (grid.inside(n) and (grid.get(n) - grid.get(p)) == 1) {
                        // std.debug.print("{any} ({d}) + {any} -> {any} ({d})\n", .{ p, grid.get(p), dp, n, grid.get(n) });
                        try stack.append(n);
                    }
                }
            }
            total += total_reaches.count();
        }
    }
    // std.debug.print("total => {d}\n", .{total});
    return total;
}

fn part2(alloc: std.mem.Allocator, input: []const u8) !usize {
    const grid = try Grid.init(alloc, input);
    defer grid.deinit();

    // print grid
    // std.debug.print("{}\n", .{grid});

    const neighbors = [_]Point{
        Point{ .i = -1, .j = 0 },
        Point{ .i = 1, .j = 0 },
        Point{ .i = 0, .j = 1 },
        Point{ .i = 0, .j = -1 },
    };

    var stack = try std.ArrayList(Point).initCapacity(alloc, grid.nrows * grid.ncols);
    defer stack.deinit();

    var total: usize = 0;
    for (0..grid.nrows) |i| {
        for (0..grid.ncols) |j| {
            if (grid.field[i][j] != 0) continue;
            // var total_reaches = std.AutoArrayHashMap(Point, void).init(alloc);
            // defer total_reaches.deinit();

            // depth-first-search
            defer stack.clearRetainingCapacity();
            try stack.append(Point{ .i = @intCast(i), .j = @intCast(j) });
            while (stack.popOrNull()) |p| {
                if (grid.get(p) == 9) {
                    // std.debug.print("reach 9 at {any}\n", .{p});
                    total += 1;
                    // try total_reaches.put(p, {});
                    continue;
                    // break;
                }
                for (neighbors) |dp| {
                    const n = p.add(dp);
                    // std.debug.print("{any} + {any} -> {any} ({})\n", .{ p, dp, n, grid.inside(n) });
                    if (grid.inside(n) and (grid.get(n) - grid.get(p)) == 1) {
                        // std.debug.print("{any} ({d}) + {any} -> {any} ({d})\n", .{ p, grid.get(p), dp, n, grid.get(n) });
                        try stack.append(n);
                    }
                }
            }
            // total += total_reaches.count();
        }
    }
    // std.debug.print("total => {d}\n", .{total});
    return total;
}

test "part 1" {
    const alloc = std.testing.allocator;

    const input_1 =
        \\0123
        \\1234
        \\8765
        \\9876
    ;

    try std.testing.expectEqual(1, try part1(alloc, input_1));

    const input_2 =
        \\1110111
        \\1111111
        \\1112111
        \\6543456
        \\7111117
        \\8111118
        \\9111119
    ;

    try std.testing.expectEqual(2, try part1(alloc, input_2));

    const input_3 =
        \\1190119
        \\1111198
        \\1112117
        \\6543456
        \\7651987
        \\8761111
        \\9871111
    ;

    try std.testing.expectEqual(4, try part1(alloc, input_3));

    const input_4 =
        \\1011911
        \\2111811
        \\3111711
        \\4567654
        \\1118113
        \\1119112
        \\1111101
    ;

    try std.testing.expectEqual(3, try part1(alloc, input_4));
}

test "part 2" {
    const alloc = std.testing.allocator;

    const input_1 =
        \\2222202
        \\2243212
        \\2252222
        \\2265432
        \\2272242
        \\2287652
        \\2292222
    ;

    try std.testing.expectEqual(3, try part2(alloc, input_1));

    const input_2 =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;

    try std.testing.expectEqual(81, try part2(alloc, input_2));
}
