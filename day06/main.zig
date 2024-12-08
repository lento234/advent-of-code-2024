const std = @import("std");

const Direction = enum(u8) {
    north = '^',
    east = '>',
    south = 'v',
    west = '<',
};

const Head = struct {
    pos: Pos,
    dir: Direction,

    const Self = @This();

    pub fn next(self: Self) ?Pos {
        const pos = switch (self.dir) {
            .north => if (self.pos.i == 0) null else Pos{ .i = self.pos.i - 1, .j = self.pos.j },
            .south => Pos{ .i = self.pos.i + 1, .j = self.pos.j },
            .east => Pos{ .i = self.pos.i, .j = self.pos.j + 1 },
            .west => if (self.pos.j == 0) null else Pos{ .i = self.pos.i, .j = self.pos.j - 1 },
        };
        return pos;
    }
};

const Pos = struct {
    i: usize,
    j: usize,
};

const Grid = struct {
    const Self = @This();
    nrows: usize,
    ncols: usize,
    start: Head,
    // alloc: std.mem.Allocator,
    obstacles: std.AutoArrayHashMap(Pos, void),

    pub fn init(alloc: std.mem.Allocator, input: []const u8) !Self {
        var it = std.mem.tokenizeScalar(u8, input, '\n');
        var obstacles = std.AutoArrayHashMap(Pos, void).init(alloc);
        // defer obstacles.deinit();
        var row: usize = 0;
        var ncols: usize = undefined;
        var start: Head = undefined;

        while (it.next()) |line| {
            if (row == 0) ncols = line.len;
            for (line, 0..) |c, col| {
                switch (c) {
                    '#' => try obstacles.put(Pos{ .i = row, .j = col }, {}),
                    '^' => start = Head{ .pos = Pos{ .i = row, .j = col }, .dir = .north },
                    else => continue,
                }
            }
            row += 1;
        }
        return Self{
            .nrows = row,
            .ncols = ncols,
            .start = start,
            // .alloc = alloc,
            .obstacles = obstacles,
        };
    }

    pub fn deinit(self: *Self) void {
        // self.alloc.free(self.obstacles);
        self.obstacles.deinit();
    }

    // pub fn get(self: Self, p: Pos) u8 {
    //     return self.map[p.pos[0]][p.pos[1]];
    // }

    // pub fn peek(self: Self) ?u8 {
    //     return switch (self.head.dir) {
    //         .north => if (self.head.pos[0] > 0) self.get(self.head.pos[0] - 1, self.head.pos[1]) else null,
    //         .south => if (self.head.pos[0] < self.nrows - 1) self.get(self.head.pos[0] + 1, self.head.pos[1]) else null,
    //         .east => if (self.head.pos[1] < self.ncols - 1) self.get(self.head.pos[0], self.head.pos[1] + 1) else null,
    //         .west => if (self.head.pos[1] > 0) self.get(self.head.pos[0], self.head.pos[1] - 1) else null,
    //     };
    // }
    //
    // pub fn turn(self: *Self, mark: bool) void {
    //     switch (self.head.dir) {
    //         .north => self.head.dir = .east,
    //         .south => self.head.dir = .west,
    //         .east => self.head.dir = .south,
    //         .west => self.head.dir = .north,
    //     }
    //     if (mark)
    //         self.map[self.head.pos[0]][self.head.pos[1]] = @intFromEnum(self.head.dir);
    // }
    //
    // pub fn walk(self: *Self, mark: bool) void {
    //     switch (self.head.dir) {
    //         .north => self.head.pos[0] -= 1,
    //         .south => self.head.pos[0] += 1,
    //         .east => self.head.pos[1] += 1,
    //         .west => self.head.pos[1] -= 1,
    //     }
    //     if (mark) {
    //         self.map[self.head.pos[0]][self.head.pos[1]] = @intFromEnum(self.head.dir);
    //     } else {
    //         self.map[self.head.pos[0]][self.head.pos[1]] = 'X';
    //     }
    // }

    pub fn inside(self: Self, i: i64, j: i64) bool {
        return i >= 0 and i < self.nrows and j >= 0 and j < self.ncols;
    }
};

fn part1(alloc: std.mem.Allocator, input: []const u8) !usize {
    var grid = try Grid.init(alloc, input);
    defer grid.deinit();

    var visits = std.AutoArrayHashMap(Pos, void).init(alloc);
    defer visits.deinit();

    var head = grid.start;
    try visits.put(head.pos, {});
    while (head.next()) |next| {
        if (!grid.inside(@intCast(next.i), @intCast(next.j))) break;
        if (grid.obstacles.contains(next)) {
            head.dir = switch (head.dir) {
                .north => .east,
                .south => .west,
                .east => .south,
                .west => .north,
            };
        } else {
            head.pos = next;
            try visits.put(next, {});
        }
    }
    return visits.count();
}

fn part2(alloc: std.mem.Allocator, input: []const u8) !usize {
    var grid = try Grid.init(alloc, input);
    defer grid.deinit();

    var path = std.AutoArrayHashMap(Pos, Head).init(alloc);
    defer path.deinit();

    const start = grid.start.pos;
    // var obstacles = grid.obstacles;
    {
        var head = grid.start;
        while (head.next()) |next| {
            if (!grid.inside(@intCast(next.i), @intCast(next.j))) break;
            if (grid.obstacles.contains(next)) {
                head.dir = switch (head.dir) {
                    .north => .east,
                    .south => .west,
                    .east => .south,
                    .west => .north,
                };
            } else {
                head.pos = next;
                if ((next.i != start.i or next.j != start.j) and !path.contains(head.pos)) {
                    try path.put(head.pos, head);
                }
            }
        }
    }

    // std.debug.print("head => {any}\n", .{head.pos});
    // std.debug.print("start => {any}\n", .{grid.start.pos});
    // std.debug.print("path => {any}\n", .{path.count()});

    // const
    var visits = std.AutoArrayHashMap(Head, void).init(alloc);
    var obstacles = try grid.obstacles.clone();
    defer obstacles.deinit();
    defer visits.deinit();

    var total: usize = 0;
    for (path.keys(), 0..) |p, i| {
        // const p = kv.key;
        defer visits.clearRetainingCapacity();
        try obstacles.put(p, {});
        defer _ = obstacles.fetchSwapRemove(p);

        var head = if (i == 0) grid.start else path.values()[i - 1];
        while (head.next()) |next| {
            if (!grid.inside(@intCast(next.i), @intCast(next.j))) break;
            if (obstacles.contains(next)) {
                head.dir = switch (head.dir) {
                    .north => .east,
                    .south => .west,
                    .east => .south,
                    .west => .north,
                };
            } else {
                head.pos = next;
                if (visits.contains(head)) {
                    total += 1;
                    break;
                }
                try visits.put(head, {});
            }
        }
    }
    return total;
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

    const result2 = try part2(alloc, input);
    try stdout.print("Part 2: {d}\n", .{result2});
}

test "part 1" {
    const alloc = std.testing.allocator;
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    defer alloc.free(input);
    try std.testing.expectEqual(41, try part1(alloc, input));
}

test "part 2" {
    const alloc = std.testing.allocator;
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 12);
    defer alloc.free(input);
    try std.testing.expectEqual(6, try part2(alloc, input));
}
