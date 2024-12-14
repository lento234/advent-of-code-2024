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

    const result2 = try part2(alloc, input);
    try stdout.print("Part 2: {d}\n", .{result2});
}

const Direction = enum {
    const Self = @This();
    north,
    south,
    east,
    west,
    northeast,
    southeast,
    northwest,
    southwest,

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{s}", .{switch (self) {
            .north => "north",
            .south => "south",
            .east => "east",
            .west => "west",
            .northeast => "northeast",
            .southeast => "southeast",
            .northwest => "northwest",
            .southwest => "southwest",
        }});
    }
};

const Edge = struct {
    const Self = @This();
    p: Point,
    d: Direction,

    pub fn equal(self: Self, other: Self) bool {
        return self.p.i == other.p.i and self.p.j == other.p.j and self.d == other.d;
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{{{any}, {any}}}", .{ self.p, self.d });
    }
};

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
            // diagonals
            .northeast => Point{ .i = self.i -% 1, .j = self.j + 1 },
            .southeast => Point{ .i = self.i + 1, .j = self.j + 1 },
            .northwest => Point{ .i = self.i -% 1, .j = self.j -% 1 },
            .southwest => Point{ .i = self.i + 1, .j = self.j -% 1 },
        };
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("({d}, {d})", .{ self.i, self.j });
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

    pub inline fn inside(self: Self, p: Point) bool {
        return p.i < self.nrows and p.j < self.ncols;
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

    pub fn nCorners(self: Self, p: Point) u64 {
        const c = self.get(p);
        const north = p.get(.north);
        const south = p.get(.south);
        const east = p.get(.east);
        const west = p.get(.west);
        const northeast = p.get(.northeast);
        const southeast = p.get(.southeast);
        const northwest = p.get(.northwest);
        const southwest = p.get(.southwest);

        var n: u64 = 0;

        for ([_]Direction{ .southwest, .southeast, .northwest, .northeast }) |d| {
            switch (d) {
                .southwest => {
                    if ((self.get(south) != c and self.get(west) != c) or (self.get(south) == c and self.get(west) == c and self.get(southwest) != c))
                        n += 1;
                },
                .southeast => {
                    if ((self.get(south) != c and self.get(east) != c) or (self.get(south) == c and self.get(east) == c and self.get(southeast) != c))
                        n += 1;
                },
                .northwest => {
                    if ((self.get(north) != c and self.get(west) != c) or (self.get(north) == c and self.get(west) == c and self.get(northwest) != c))
                        n += 1;
                },
                .northeast => {
                    if ((self.get(north) != c and self.get(east) != c) or (self.get(north) == c and self.get(east) == c and self.get(northeast) != c))
                        n += 1;
                },
                else => unreachable,
            }
        }
        return n;
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

fn part2(alloc: std.mem.Allocator, input: []const u8) !u64 {
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
        var area: u64 = 0;
        var n_sides: u64 = 0;

        // var lowet_point = start;

        // search for all valid regions
        while (stack.popOrNull()) |p| {
            // remove the point from total lists
            _ = tovisit.fetchOrderedRemove(p);

            // calculate area and sides
            area += 1;
            n_sides += grid.nCorners(p);

            // add neighbors
            var buffer: [4]Point = undefined;
            const neighbors = grid.neighbors(&buffer, p);
            for (neighbors) |n| {
                // if the neighors does not much the start ignore it
                if (grid.get(n).? != c or !tovisit.contains(n)) continue;
                // std.debug.print("neighbor -> {any} added\n", .{n});
                // remove neighbor from tovisit and put it into the stack
                // add the neighbor to the stack
                try stack.append(tovisit.fetchOrderedRemove(n).?.key);
            }
        }
        price += area * n_sides;
    }
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

test "part 2" {
    const alloc = std.testing.allocator;

    const input_a =
        \\AAAA
        \\BBCD
        \\BBCC
        \\EEEC
        \\
    ;
    try std.testing.expectEqual(80, try part2(alloc, input_a));

    const input_b =
        \\OOOOO
        \\OXOXO
        \\OOOOO
        \\OXOXO
        \\OOOOO
        \\
    ;
    try std.testing.expectEqual(436, try part2(alloc, input_b));

    const input_c =
        \\EEEEE
        \\EXXXX
        \\EEEEE
        \\EXXXX
        \\EEEEE
        \\
    ;
    try std.testing.expectEqual(236, try part2(alloc, input_c));

    const input_d =
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
    try std.testing.expectEqual(1206, try part2(alloc, input_d));
}
