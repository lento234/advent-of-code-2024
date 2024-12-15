const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of code: day {}\n", .{14});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // read input
    const input = try std.fs.cwd().readFileAlloc(alloc, "input.txt", 1 << 15);

    const result1 = try part1(alloc, input, 100, Vec2{ .x = 101, .y = 103 });
    try stdout.print("Part 1: {d}\n", .{result1});

    const result2 = try part2(alloc, input, 10_000, Vec2{ .x = 101, .y = 103 });
    try stdout.print("Part 2: {}\n", .{result2});
}

const Robot = struct {
    const Self = @This();
    p: Vec2,
    v: Vec2,

    pub fn init(line: []const u8) !Robot {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const p = try Vec2.init(it.next().?);
        const v = try Vec2.init(it.next().?);
        return Robot{ .p = p, .v = v };
    }

    pub fn move(self: *Self, t: u64, limit: Vec2) void {
        self.p.x = @mod(self.p.x + self.v.x * @as(i64, @intCast(t)), limit.x);
        self.p.y = @mod(self.p.y + self.v.y * @as(i64, @intCast(t)), limit.y);
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("Robot{{p={}, v={}}}", .{ self.p, self.v });
    }
};

const Vec2 = struct {
    const Self = @This();
    x: i64,
    y: i64,

    pub fn init(text: []const u8) !Vec2 {
        var it = std.mem.tokenizeAny(u8, text, "=,");
        _ = it.next(); // name

        const x = try std.fmt.parseInt(i64, it.next().?, 10);
        const y = try std.fmt.parseInt(i64, it.next().?, 10);

        return Vec2{ .x = x, .y = y };
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("({d}, {d})", .{ self.x, self.y });
    }
};

fn part1(alloc: std.mem.Allocator, input: []const u8, seconds: u64, bounds: Vec2) !u64 {
    // std.debug.print("input:\n{s}\n", .{input});

    var it = std.mem.tokenizeScalar(u8, input, '\n');

    const n_robots = std.mem.count(u8, input, "\n");
    var robots = try std.ArrayList(Robot).initCapacity(alloc, n_robots);
    defer robots.deinit();
    while (it.next()) |line| {
        try robots.append(try Robot.init(line));
    }

    // move
    for (robots.items) |*robot| {
        robot.move(seconds, bounds);
    }

    // middle point
    const mid = Vec2{
        .x = @divFloor(bounds.x, 2),
        .y = @divFloor(bounds.y, 2),
    };

    // count quadrants
    var quadrands: [4]u64 = .{ 0, 0, 0, 0 };
    for (robots.items) |robot| {
        if (robot.p.x == mid.x or robot.p.y == mid.y) continue;
        const q: usize = @as(usize, @intFromBool(robot.p.y < mid.y)) + 2 * @as(usize, @intFromBool(robot.p.x < mid.x));
        quadrands[q] += 1;
    }
    const total: u64 = quadrands[0] * quadrands[1] * quadrands[2] * quadrands[3];

    return total;
}

fn print(robots: []Robot, bounds: Vec2) void {
    var buffer: [20000]u8 = undefined;
    const grid = buffer[0..@intCast(bounds.x * bounds.y)];

    for (robots) |robot| {
        const k = robot.p.x + bounds.x * robot.p.y;
        grid[@intCast(k)] = 'X';
    }

    std.debug.print("Grid ({d} x {d})\n", .{ bounds.y, bounds.x });
    for (0..@intCast(bounds.y)) |i| {
        for (0..@intCast(bounds.x)) |j| {
            const k = j + @as(usize, @intCast(bounds.x)) * i;
            if (grid[k] == 'X') {
                std.debug.print("X", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

fn mean(robots: []Robot) Vec2 {
    var m = Vec2{ .x = 0, .y = 0 };
    for (robots) |robot| {
        m.x += robot.p.x;
        m.y += robot.p.y;
    }
    m.x = @divFloor(m.x, @as(i64, @intCast(robots.len)));
    m.y = @divFloor(m.y, @as(i64, @intCast(robots.len)));
    return m;
}

fn variance(robots: []Robot) i64 {
    const m = mean(robots);

    var v: i64 = 0;
    for (robots) |robot| {
        v += std.math.pow(i64, robot.p.x - m.x, 2) + std.math.pow(i64, robot.p.y - m.y, 2);
    }
    v = @divFloor(v, @as(i64, @intCast(robots.len)));
    return v;
}

fn part2(alloc: std.mem.Allocator, input: []const u8, seconds: u64, bounds: Vec2) !usize {
    // std.debug.print("input:\n{s}\n", .{input});

    var it = std.mem.tokenizeScalar(u8, input, '\n');

    const n_robots = std.mem.count(u8, input, "\n");
    var robots = try std.ArrayList(Robot).initCapacity(alloc, n_robots);
    defer robots.deinit();
    while (it.next()) |line| {
        try robots.append(try Robot.init(line));
    }

    // initial
    // std.debug.print("initial: mean = {}, var = {}\n", .{ mean(robots.items), variance(robots.items) });
    // print(robots.items, bounds);

    var variances = try std.ArrayList(i64).initCapacity(alloc, seconds);
    defer variances.deinit();
    try variances.append(variance(robots.items));

    for (0..seconds) |_| {
        // move
        for (robots.items) |*robot| {
            robot.move(1, bounds);
        }
        try variances.append(variance(robots.items));
        // std.debug.print("after {d} seconds: mean = {}, var = {}\n", .{ i, mean(robots.items), variance(robots.items) });
        // std.debug.print("after {d} seconds:\n", .{i});
        // print(robots.items, bounds);
    }
    // print(robots.items, bounds);

    return std.mem.indexOfMin(i64, variances.items);
}

test "part 1" {
    const alloc = std.testing.allocator;
    const input =
        \\p=0,4 v=3,-3
        \\p=6,3 v=-1,-3
        \\p=10,3 v=-1,2
        \\p=2,0 v=2,-1
        \\p=0,0 v=1,3
        \\p=3,0 v=-2,-2
        \\p=7,6 v=-1,-3
        \\p=3,0 v=-1,-2
        \\p=9,3 v=2,3
        \\p=7,3 v=-1,2
        \\p=2,4 v=2,-3
        \\p=9,5 v=-3,-3
        \\
    ;

    try std.testing.expectEqual(
        12,
        try part1(alloc, input, 100, Vec2{ .x = 11, .y = 7 }),
    );
}

test "part 2" {
    const alloc = std.testing.allocator;
    const input =
        \\p=0,4 v=3,-3
        \\p=6,3 v=-1,-3
        \\p=10,3 v=-1,2
        \\p=2,0 v=2,-1
        \\p=0,0 v=1,3
        \\p=3,0 v=-2,-2
        \\p=7,6 v=-1,-3
        \\p=3,0 v=-1,-2
        \\p=9,3 v=2,3
        \\p=7,3 v=-1,2
        \\p=2,4 v=2,-3
        \\p=9,5 v=-3,-3
        \\
    ;

    try part2(alloc, input, 100, Vec2{ .x = 11, .y = 7 });
}
