const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of code: day {}\n", .{12});

    // allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // read input
    const input = try std.fs.cwd().readFileAlloc(alloc, "input.txt", 1 << 15);

    const result1 = try part1(alloc, input);
    try stdout.print("Part 1: {d}\n", .{result1});
    //
    // const result2 = try part1and2(alloc, input, 75);
    // try stdout.print("Part 2: {d}\n", .{result2});
}

const Direction = enum { north, south, east, west };

const Point = struct {
    const Self = @This();
    i: usize,
    j: usize,

    fn get(self: Self, dir: Direction) Point {
        return switch (dir) {
            .north => Point{ .i = self.i -% 1, .j = self.j },
            .south => Point{ .i = self.i + 1, .j = self.j },
            .east => Point{ .i = self.i, .j = self.j + 1 },
            .west => Point{ .i = self.i, .j = self.j -% 1 },
        };
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("p({d}, {d})", .{ self.i, self.j });
    }
};

const Grid = struct {
    const Self = @This();
    nrows: usize,
    ncols: usize,
    field: []const u8,
    alloc: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator, buffer: []const u8) !Self {
        var it = std.mem.tokenizeScalar(u8, buffer, '\n');
        const ncols: usize = it.next().?.len;
        const nrows: usize = std.mem.count(u8, buffer, "\n");

        var arr = try std.ArrayList(u8).initCapacity(alloc, ncols * nrows);

        it.reset();
        while (it.next()) |line| {
            try arr.appendSlice(std.mem.trimRight(u8, line, "\n"));
        }

        const field: []const u8 = try arr.toOwnedSlice();

        return Self{
            .nrows = nrows,
            .ncols = ncols,
            .field = field,
            .alloc = alloc,
        };
    }

    pub fn deinit(self: Self) void {
        self.alloc.free(self.field);
    }

    pub fn inside(self: Self, p: Point) bool {
        return p.i >= 0 and p.i < self.nrows and p.j >= 0 and p.j < self.ncols;
    }

    pub fn get(self: Self, p: Point) ?u8 {
        if (!self.inside(p)) return null;
        const k = p.j + p.i * self.ncols;
        return self.field[k];
    }

    pub fn neighbors(self: Self, buffer: []Point, p: Point) []Point {
        var idx: usize = 0;
        for ([_]Direction{ .north, .south, .east, .west }) |d| {
            if (self.inside(p.get(d))) {
                buffer[idx] = p.get(d);
                idx += 1;
            }
        }
        return buffer[0..idx];
    }

    pub fn perimeter(self: Self, p: Point) usize {
        var perim: usize = 0;
        const c = self.get(p);

        for ([_]Direction{ .north, .south, .east, .west }) |d| {
            const n = p.get(d); // neighbor
            if ((self.inside(n) and self.get(n) != c) or !self.inside(n))
                perim += 1;
        }
        return perim;
    }

    pub fn print(self: Self) void {
        std.debug.print("Grid({d} x {d}):\n", .{ self.nrows, self.ncols });
        for (0..self.nrows) |i| {
            std.debug.print(" ", .{});
            for (0..self.ncols) |j| {
                const c = self.get(Point{ .i = i, .j = j }).?;
                std.debug.print("{c}", .{c});
            }
            std.debug.print("\n", .{});
        }
    }
};

fn part1(alloc: std.mem.Allocator, input: []const u8) !u64 {
    // std.debug.print("input:\n\n{s}\n", .{input});

    const grid = try Grid.init(alloc, input);
    defer grid.deinit();

    var tovisit = std.AutoArrayHashMap(Point, void).init(alloc);
    defer tovisit.deinit();
    for (0..grid.nrows) |i| {
        for (0..grid.ncols) |j| {
            try tovisit.put(.{ .i = i, .j = j }, {});
        }
    }

    var stack = try std.ArrayList(Point).initCapacity(alloc, grid.ncols * grid.nrows);
    defer stack.deinit();

    var price: u64 = 0;

    while (tovisit.popOrNull()) |kv| {
        defer stack.clearRetainingCapacity();

        // get next starting point
        const start = kv.key;
        const c = grid.get(start).?;
        try stack.append(start);
        // std.debug.print("start: {?} = {c} -> ", .{ start, c });

        var perimeter: u64 = 0;
        var area: u64 = 0;

        // search for all valid regions
        while (stack.popOrNull()) |p| {
            // remove the point from total lists
            _ = tovisit.swapRemove(p);

            // calculatea area and perimeter
            area += 1;
            perimeter += grid.perimeter(p);

            // add neighbors
            var buffer: [4]Point = undefined;
            const neighbors = grid.neighbors(&buffer, p);
            // std.debug.print("all neighbor -> {any}\n", .{neighbors});
            for (neighbors) |n| {
                // if the neighors does not much the start ignore it
                if (grid.get(n).? != c or !tovisit.contains(n)) continue;
                // std.debug.print("neighbor -> {any} added\n", .{n});
                // remove neighbor from tovisit and put it into the stack
                // add the neighbor to the stack
                try stack.append(tovisit.fetchOrderedRemove(n).?.key);
            }
        }
        // std.debug.print("area = {d}, perimeter = {d}\n", .{ area, perimeter });
        price += area * perimeter;
    }

    // std.debug.print("total price = {d}\n", .{price});
    return price;
}

test "part 1" {
    const alloc = std.testing.allocator;

    const input_a =
        \\AAAA
        \\BBCD
        \\BBCC
        \\EEEC
        \\
    ;
    try std.testing.expectEqual(140, try part1(alloc, input_a));

    const input_b =
        \\OOOOO
        \\OXOXO
        \\OOOOO
        \\OXOXO
        \\OOOOO
        \\
    ;
    try std.testing.expectEqual(772, try part1(alloc, input_b));

    const input_c =
        \\RRRRIICCFF
        \\RRRRIICCCF
        \\VVRRRCCFFF
        \\VVRCCCJFFF
        \\VVVVCJJCFE
        \\VVIVCCJJEE
        \\VVIIICJJEE
        \\MIIIIIJJEE
        \\MIIISIJEEE
        \\MMMISSJEEE
        \\
    ;
    try std.testing.expectEqual(1930, try part1(alloc, input_c));
}
