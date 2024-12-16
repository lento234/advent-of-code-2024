const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of code: day {}\n", .{15});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // read input
    const input = try std.fs.cwd().readFileAlloc(alloc, "input.txt", 1 << 15);

    const result1 = try part1(alloc, input);
    try stdout.print("Part 1: {d}\n", .{result1});
}

const Direction = enum(u8) {
    const Self = @This();
    up = '^',
    down = 'v',
    right = '>',
    left = '<',

    pub fn neg(self: Self) Direction {
        return switch (self) {
            .up => .down,
            .down => .up,
            .left => .right,
            .right => .left,
        };
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{s}", .{switch (self) {
            .up => "up",
            .down => "down",
            .right => "right",
            .left => "left",
        }});
    }
};

const Position = struct {
    const Self = @This();
    i: usize,
    j: usize,

    pub fn get(self: Self, dir: Direction) Position {
        const p = switch (dir) {
            .up => Position{ .i = self.i -% 1, .j = self.j },
            .down => Position{ .i = self.i + 1, .j = self.j },
            .left => Position{ .i = self.i, .j = self.j -% 1 },
            .right => Position{ .i = self.i, .j = self.j + 1 },
        };
        return p;
    }

    pub inline fn eql(self: Self, other: Position) bool {
        return self.i == other.i and self.j == other.j;
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("({d}, {d})", .{ self.i, self.j });
    }
};

const Grid = struct {
    const Self = @This();
    nrows: usize,
    ncols: usize,
    field: []u8,
    alloc: std.mem.Allocator,
    p: Position,

    const Part = enum { part1, part2 };

    pub fn init(alloc: std.mem.Allocator, text: []const u8, part: Part) !Grid {
        var it = std.mem.tokenizeScalar(u8, text, '\n');

        var field = std.ArrayList(u8).init(alloc);
        var ncols: usize = undefined;
        var row: usize = 0;

        var p: Position = undefined;

        while (it.next()) |line| {
            if (row == 0) {
                ncols = switch (part) {
                    .part1 => line.len,
                    .part2 => line.len * 2,
                };
            }
            for (line) |c| {
                // if (c == '@') p = Position{ .i = row, .j = col };
                switch (part) {
                    .part1 => try field.append(c),
                    .part2 => {
                        const token = switch (c) {
                            '#' => "##",
                            'O' => "[]",
                            '@' => "@.",
                            else => "..",
                        };
                        try field.appendSlice(token);
                    },
                }
            }
            row += 1;
        }

        outer: for (0..row) |i| {
            for (0..ncols) |j| {
                const k = j + i * ncols;
                if (field.items[k] == '@') {
                    p = Position{ .i = i, .j = j };
                    break :outer;
                }
            }
        }

        return Grid{
            .nrows = row,
            .ncols = ncols,
            .field = try field.toOwnedSlice(),
            .alloc = alloc,
            .p = p,
        };
    }

    pub fn deinit(self: Self) void {
        self.alloc.free(self.field);
    }

    pub inline fn inside(self: Self, p: Position) bool {
        return p.i < self.nrows and p.j < self.ncols;
    }

    pub inline fn get(self: Self, p: Position) ?u8 {
        if (!self.inside(p)) return null;
        return self.field[self.toIdx(p)];
    }

    pub inline fn toIdx(self: Self, p: Position) usize {
        return p.j + p.i * self.ncols;
    }

    pub fn swap(self: *Self, p1: Position, p2: Position) void {
        const k1 = self.toIdx(p1);
        const k2 = self.toIdx(p2);
        std.mem.swap(u8, &self.field[k1], &self.field[k2]);
    }

    pub fn moveBlock(self: *Self, p: Position, dir: Direction) void {
        std.debug.print("moving {} {}\n", .{ p, dir });
        const nbr = if (self.get(p) == ']') p.get(.left) else p.get(.right);
        std.debug.print("moving (2) {} {} \n", .{ p, dir });
        if (self.get(p) == '.' or self.get(p) == '#') return;
        std.debug.print("moving (3) {} {}\n", .{ p, dir });
        self.moveBlock(p.get(dir), dir);
        self.moveBlock(nbr.get(dir), dir);
        self.swap(p, p.get(dir));
        self.swap(nbr, nbr.get(dir));
    }

    pub fn canMoveBlock(self: *Self, p: Position, dir: Direction) bool {
        if (self.get(p) == '.') return true; // free
        if (!self.inside(p) or self.get(p) == '#') return false; // block

        std.debug.print("canMoveBlock ({}): {} -> '{c}'\n", .{ p, p, self.get(p).? });

        // check if its a block
        const nbr = if (self.get(p) == ']') p.get(.left) else p.get(.right);
        std.debug.print("canMoveBlock ({}): nbr {} -> '{c}'\n", .{ p, nbr, self.get(nbr).? });

        // recursively check if above the block is free
        if (self.canMoveBlock(p.get(dir), dir) and self.canMoveBlock(nbr.get(dir), dir)) {
            std.debug.print("canMoveBlock ({}): inside if, can both move {} -> '{c}', {} -> '{c}'\n", .{ p, p, self.get(p.get(dir)).?, nbr, self.get(nbr.get(dir)).? });
            return true;
        }
        std.debug.print("canMoveBlock ({}): AFTER if, CANNNOT move {} -> '{c}', {} -> '{c}'\n", .{ p, p, self.get(p.get(dir)).?, nbr, self.get(nbr.get(dir)).? });
        return false;
    }

    pub fn move(self: *Self, dir: Direction, part: Part) void {
        // std.debug.print("moving..{}\n", .{self.p});
        // early return if free space is not available
        const free_space = self.find(self.p, dir, '.') orelse return;

        // std.debug.print("checking if next pos is empty..\n", .{});
        // if next position is empty, just move the poointer and return
        const next = self.p.get(dir);
        if (self.get(next) == '.') {
            self.swap(self.p, next);
            self.p = next;
            return;
        }

        // third scenario, we have a 'O' in dir, so we need to move the pointer
        // and all the 'O's upto the next '.' (free space)

        // early return if block is in the way
        const block_pos = self.find(self.p, dir, '#').?;
        switch (dir) {
            .up => if (block_pos.i > free_space.i) return,
            .down => if (block_pos.i < free_space.i) return,
            .left => if (block_pos.j > free_space.j) return,
            .right => if (block_pos.j < free_space.j) return,
        }

        if (part == .part2 and (dir == .up or dir == .down)) {
            std.debug.print("special case: {} {}\n", .{ self.p, dir });
            if (self.canMoveBlock(self.p.get(dir), dir)) {
                std.debug.print("can move {} {}\n", .{ self.p, dir });
                self.moveBlock(self.p.get(dir), dir);
                self.swap(self.p, self.p.get(dir));
                self.p = self.p.get(dir);
            }
            return;
        }

        var p = free_space;
        // std.debug.print("third scenario..{}\n", .{p});
        while (!p.eql(self.p)) {
            // std.debug.print("swapping {} {}\n", .{ p, p.get(dir.neg()) });
            self.swap(p, p.get(dir.neg()));
            p = p.get(dir.neg());
        }
        // now update the pointer to p
        self.p = self.p.get(dir);
        // std.debug.print("done..\n", .{});
    }

    pub fn find(self: Self, p: Position, dir: Direction, haystack: u8) ?Position {
        var next = p;
        while (self.get(next)) |c| {
            if (c == haystack) return next;
            next = next.get(dir);
        }
        return null;
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Grid ({d} x {d}) p = {}:\n", .{ self.nrows, self.ncols, self.p });
        for (0..self.nrows) |i| {
            for (0..self.ncols) |j| {
                try writer.print("{c}", .{self.get(.{ .i = i, .j = j }).?});
            }
            try writer.print("\n", .{});
        }
    }
};

fn part1(alloc: std.mem.Allocator, input: []const u8) !u64 {
    // std.debug.print("input:\n{s}\n", .{input});

    const idx = std.mem.indexOf(u8, input, "\n\n").?;
    // std.debug.print("idx => {any}\n", .{idx});
    var grid = try Grid.init(alloc, input[0..idx], .part1);
    defer grid.deinit();

    // std.debug.print("{}\n", .{grid});

    // movements
    // var it = std.mem.splitScalar(u8, input[idx+1..], '\n');
    // var k: usize = 0;
    for (input[idx + 1 ..]) |c| {
        if (c == '\n') continue;
        const dir = @as(Direction, @enumFromInt(c));
        // std.debug.print("[{d:03}]: move {} ({c})\n", .{ k, dir, c });

        grid.move(dir, .part1);
        // std.debug.print("{}\n", .{grid});
        // k += 1;
    }

    var total: u64 = 0;
    for (0..grid.nrows) |i| {
        for (0..grid.ncols) |j| {
            if (grid.get(.{ .i = i, .j = j }) == 'O') total += 100 * i + j;
        }
    }

    // std.debug.print("total => {}\n", .{total});
    // std.debug.print("p => {?}\n", .{grid.find(grid.p, .down, 'O')});
    return total;
}

fn part2(alloc: std.mem.Allocator, input: []const u8) !void {
    std.debug.print("input:\n{s}\n", .{input});

    const idx = std.mem.indexOf(u8, input, "\n\n").?;
    // std.debug.print("idx => {any}\n", .{idx});
    var grid = try Grid.init(alloc, input[0..idx], .part2);
    defer grid.deinit();

    std.debug.print("initial:\n{}\n", .{grid});

    var k: usize = 0;
    for (input[idx + 1 ..]) |c| {
        if (c == '\n') continue;
        const dir = @as(Direction, @enumFromInt(c));
        std.debug.print("[{d:03}]: move {} ({c})\n", .{ k, dir, c });

        grid.move(dir, .part2);
        std.debug.print("{}\n", .{grid});
        k += 1;
    }
    std.debug.print("after:\n{}\n", .{grid});

    var total: u64 = 0;
    for (0..grid.nrows) |i| {
        for (0..grid.ncols) |j| {
            if (grid.get(.{ .i = i, .j = j }) == '[') {
                std.debug.print("{d}, {d} -> {d}\n", .{ i, j, 100 * i + j });
                total += 100 * i + j;
            }
        }
    }
    std.debug.print("total => {d}\n", .{total});
}

test "part 1" {
    const alloc = std.testing.allocator;

    const small_input =
        \\########
        \\#..O.O.#
        \\##@.O..#
        \\#...O..#
        \\#.#.O..#
        \\#...O..#
        \\#......#
        \\########
        \\
        \\<^^>>>vv<v>>v<<
        \\
    ;
    try std.testing.expectEqual(2028, try part1(alloc, small_input));

    // larger test sample
    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 15);
    defer alloc.free(input);

    try std.testing.expectEqual(10092, try part1(alloc, input));
}

test "part 2" {
    const alloc = std.testing.allocator;
    const small_input =
        \\#######
        \\#...#.#
        \\#.....#
        \\#..OO@#
        \\#..O..#
        \\#.....#
        \\#######
        \\
        \\<vv<<^^<<^^
        \\
    ;
    try std.testing.expectEqual(618, try part2(alloc, small_input));
}
