const std = @import("std");

const Direction = enum { north, south, east, west };

const Point = struct {
    const Self = @This();
    i: usize,
    j: usize,

    fn get(self: Self, dir: Direction) Point {
        return switch (dir) {
            .north => Point{ .i = self.i - 1, .j = self.j },
            .south => Point{ .i = self.i + 1, .j = self.j },
            .east => Point{ .i = self.i, .j = self.j + 1 },
            .west => Point{ .i = self.i, .j = self.j - 1 },
        };
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

fn part1(alloc: std.mem.Allocator, input: []const u8) !void {
    std.debug.print("input:\n\n{s}\n", .{input});

    const grid = try Grid.init(alloc, input);
    defer grid.deinit();

    var tovisit = std.AutoArrayHashMap(Point, void).init(alloc);
    defer tovisit.deinit();
    for (0..grid.nrows) |i| {
        for (0..grid.ncols) |j| {
            try tovisit.put(.{ .i = i, .j = j }, {});
        }
    }

    // const bff: [100]u8 = undefined;
    // std.heap.FixedBufferAllocator.init(&bff);

    var stack = try std.ArrayList(Point).initCapacity(alloc, grid.ncols * grid.nrows);
    defer stack.deinit();

    while (tovisit.popOrNull()) |kv| {
        defer stack.clearRetainingCapacity();

        // get next starting point
        const start = kv.key;
        const c = grid.get(start).?;
        try stack.append(start);
        std.debug.print("start: {?} = {c} -> ", .{ start, c });

        var buffer: [4]Point = undefined;
        const neighbors = grid.neighbors(&buffer, start);

        std.debug.print("neighbors -> {any}\n", .{neighbors});
        break;

        // // var perimeter: u64 = 0;
        // var area: u64 = 0;
        //
        // // search for all valid regions
        // while (stack.popOrNull()) |p| {
        //     // remove the point from total lists
        //     _ = tovisit.swapRemove(p);
        //
        //     const buffer: [4]Point = undefined;
        //     const neighbors = grid.neighbors(buffer, p);
        //     for (neighbors) |n| {
        //         // if the neighors does not much the start ignore it
        //         if (grid.get(n).? != c) continue;
        //         // perimeter += grid.perimeter(n, c);
        //         area += 1;
        //     }
        // }
        // std.debug.print("area = {d}\n", .{area});
    }
}

test "part 1" {
    const alloc = std.testing.allocator;
    const input =
        \\AAAA
        \\BBCD
        \\BBCC
        \\EEEC
        \\
    ;

    try part1(alloc, input);
}
