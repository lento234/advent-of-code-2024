const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of code: day {}\n", .{16});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // read input
    const input = try std.fs.cwd().readFileAlloc(alloc, "input.txt", 1 << 15);

    const result1 = (try part1(alloc, input)).?;
    try stdout.print("Part 1: {d}\n", .{result1});
}

const Dir = enum {
    const Self = @This();
    east,
    north,
    west,
    south,

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        const str = switch (self) {
            .east => "east",
            .north => "north",
            .west => "west",
            .south => "south",
        };
        try writer.print("{s}", .{str});
    }
};

const Pos = struct {
    const Self = @This();
    i: usize,
    j: usize,

    pub fn init(k: usize, ncols: usize) Pos {
        return Pos{ .i = @divFloor(k, ncols), .j = @mod(k, ncols) };
    }

    pub fn look(self: Self, dir: Dir) Pos {
        return switch (dir) {
            .east => Pos{ .i = self.i, .j = self.j + 1 },
            .west => Pos{ .i = self.i, .j = self.j -% 1 },
            .north => Pos{ .i = self.i -% 1, .j = self.j },
            .south => Pos{ .i = self.i + 1, .j = self.j },
        };
    }

    pub fn toIdx(self: Self, ncols: usize) usize {
        return self.j + self.i * ncols;
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("({d}, {d})", .{ self.i, self.j });
    }
};

const State = struct {
    const Self = @This();
    p: Pos,
    d: Dir,
    score: i64 = 0,
    turns: i64 = 0,
    steps: i64 = 0,
    prev: ?Pos = null,

    pub fn lessThan(context: void, a: State, b: State) std.math.Order {
        _ = context;
        return std.math.order(a.score, b.score);
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{{p = {}, dir = {}, score = {d}, turns = {d}, steps = {d}, prev = {any} }}", .{
            self.p,
            self.d,
            self.score,
            self.turns,
            self.steps,
            self.prev,
        });
    }
};

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

    pub fn inside(self: Self, p: Pos) bool {
        return p.i < self.nrows and p.j < self.ncols;
    }

    pub fn get(self: Self, p: Pos) ?u8 {
        if (!self.inside(p)) return null;
        return self.map[p.toIdx(self.ncols)];
    }

    pub fn neighbors(self: Self, buffer: []State, s: State) []State {
        var idx: usize = 0;
        for ([_]Dir{ .east, .west, .north, .south }) |dir| {
            const nbr = s.p.look(dir);
            if (self.inside(nbr) and self.get(nbr) != '#') {
                const dscore: i64, const dsteps: i64, const dturns: i64 = switch (s.d) {
                    .east => switch (dir) {
                        .east => .{ 1, 1, 0 },
                        .west => .{ 2001, 1, 2 },
                        .north, .south => .{ 1001, 1, 1 },
                    },
                    .west => switch (dir) {
                        .west => .{ 1, 1, 0 },
                        .east => .{ 2001, 1, 2 },
                        .north, .south => .{ 1001, 1, 1 },
                    },
                    .north => switch (dir) {
                        .north => .{ 1, 1, 0 },
                        .south => .{ 2001, 1, 2 },
                        .east, .west => .{ 1001, 1, 1 },
                    },
                    .south => switch (dir) {
                        .south => .{ 1, 1, 0 },
                        .north => .{ 2001, 1, 2 },
                        .east, .west => .{ 1001, 1, 1 },
                    },
                };
                buffer[idx] = State{
                    .p = nbr,
                    .d = dir,
                    .score = s.score + dscore,
                    .turns = s.turns + dturns,
                    .steps = s.steps + dsteps,
                    .prev = s.p,
                };
                idx += 1;
            }
        }
        return buffer[0..idx];
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

fn part1(alloc: std.mem.Allocator, input: []const u8) !?i64 {
    // std.debug.print("input:\n{s}\n", .{input});

    // make grid
    const grid = try Grid.init(input);

    // queue
    var queue = std.PriorityQueue(State, void, State.lessThan).init(alloc, {});
    defer queue.deinit();

    // add the start
    try queue.add(State{ .p = grid.start, .d = .east, .score = 0 });

    var visited = std.AutoHashMap(Pos, void).init(alloc);
    defer visited.deinit();

    const score: ?i64 = outer: {
        while (queue.removeOrNull()) |s| {
            if (grid.get(s.p) == 'E') {
                break :outer s.score;
            }
            if (visited.contains(s.p)) continue;
            try visited.put(s.p, {});

            // add neighbors
            var buffer: [4]State = undefined;
            const nbrs = grid.neighbors(&buffer, s);
            for (nbrs) |next| {
                try queue.add(next);
            }
        }
        break :outer null;
    };

    return score;
}

fn part2(alloc: std.mem.Allocator, input: []const u8) !void {
    std.debug.print("input:\n{s}\n", .{input});

    // make grid
    const grid = try Grid.init(input);

    var costbuffer: [10000]i64 = undefined;
    var cost = costbuffer[0..grid.map.len];
    for (0..cost.len) |i| {
        cost[i] = std.math.maxInt(i64);
    }

    // queue
    var queue = std.PriorityQueue(State, void, State.lessThan).init(alloc, {});
    defer queue.deinit();

    // add the start
    try queue.add(State{ .p = grid.start, .d = .east, .score = 0 });
    cost[grid.start.toIdx(grid.ncols)] = 0;

    var visited = std.AutoHashMap(Pos, State).init(alloc);
    defer visited.deinit();

    while (queue.removeOrNull()) |s| {
        if (visited.contains(s.p)) continue;
        try visited.put(s.p, s);
        if (grid.get(s.p) == 'E') {
            std.debug.print("---> found 'E' -> {}\n", .{s});
            // break :outer s.score;
        }
        std.debug.print("q => {}\n", .{s});

        // add neighbors
        var buffer: [4]State = undefined;
        const nbrs = grid.neighbors(&buffer, s);
        for (nbrs) |next| {
            if (cost[next.p.toIdx(grid.ncols)] > next.score) cost[next.p.toIdx(grid.ncols)] = next.score;
            // const next = State{ .p = n.p, .d = n.d, .score = s.score + n.score };
            // std.debug.print(" -> neigbor {} \n", .{next});
            try queue.add(next);
        }
    }
    std.debug.print("visited => {}\n", .{visited.count()});

    // var it = visited.iterator();
    // while (it.next()) |i| {
    //     std.debug.print("val: {any}\n", .{i.value_ptr});
    // }

    // var mapbuffer: [10000]u8 = undefined;
    // var map = mapbuffer[0..grid.map.len];
    // @memcpy(map, grid.map);
    //
    // var steps: i64 = 0;
    // var cur: Pos = grid.end;
    // map[cur.toIdx(grid.ncols)] = 'O';
    // var i: usize = 0;
    // while (i < 40) : (i += 1) {
    //     if (visited.get(cur)) |p| {
    //         cur = p.prev.?;
    //         map[cur.toIdx(grid.ncols)] = 'O';
    //         std.debug.print("cur: {any}, steps = {}\n", .{ cur, steps });
    //         if (cur.i == grid.start.i and cur.j == grid.start.j) {
    //             std.debug.print("reached end\n", .{});
    //             break;
    //         }
    //         steps += 1;
    //     } else {
    //         std.debug.print("could not find!\n", .{});
    //     }
    // }
    //
    // std.debug.print("prev: {any}\n", .{visited.get(grid.end)});
    // std.debug.print("cur: {any}, steps = {}\n", .{ cur, steps });

    // std.debug.print("map:{s}\n", .{map});
    // std.debug.print("score -> {?}\n", .{});

    std.debug.print("cost => {any}\n", .{cost});

    // return score;
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

    const alloc = std.testing.allocator;

    try std.testing.expectEqual(7036, try part1(alloc, input));

    const second_example =
        \\#################
        \\#...#...#...#..E#
        \\#.#.#.#.#.#.#.#.#
        \\#.#.#.#...#...#.#
        \\#.#.#.#.###.#.#.#
        \\#...#.#.#.....#.#
        \\#.#.#.#.#.#####.#
        \\#.#...#.#.#.....#
        \\#.#.#####.#.###.#
        \\#.#.#.......#...#
        \\#.#.###.#####.###
        \\#.#.#...#.....#.#
        \\#.#.#.#####.###.#
        \\#.#.#.........#.#
        \\#.#.#.#########.#
        \\#S#.............#
        \\#################
        \\
    ;

    try std.testing.expectEqual(11048, try part1(alloc, second_example));
}

test "part 2" {
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

    const alloc = std.testing.allocator;

    try part2(alloc, input);
    //
    // const second_example =
    //     \\#################
    //     \\#...#...#...#..E#
    //     \\#.#.#.#.#.#.#.#.#
    //     \\#.#.#.#...#...#.#
    //     \\#.#.#.#.###.#.#.#
    //     \\#...#.#.#.....#.#
    //     \\#.#.#.#.#.#####.#
    //     \\#.#...#.#.#.....#
    //     \\#.#.#####.#.###.#
    //     \\#.#.#.......#...#
    //     \\#.#.###.#####.###
    //     \\#.#.#...#.....#.#
    //     \\#.#.#.#####.###.#
    //     \\#.#.#.........#.#
    //     \\#.#.#.#########.#
    //     \\#S#.............#
    //     \\#################
    //     \\
    // ;
    //
    // try part2(alloc, second_example);
}
