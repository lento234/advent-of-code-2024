const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Advent of code: day {}\n", .{13});

    // read file
    var buffer: [2 << 14]u8 = undefined;
    const input = try std.fs.cwd().readFile("input.txt", &buffer);

    const result1 = try part1and2(input, 0);
    try stdout.print("Part 1: {d}\n", .{result1});

    const result2 = try part1and2(input, 10000000000000);
    try stdout.print("Part 2: {d}\n", .{result2});
}

fn solve(system: []i64, offset: i64) ?[2]i64 {
    const det = calcDeterminant(system[0..4]);
    if (det == 0) return null;

    const a_nom = (system[4] + offset) * system[3] - system[2] * (system[5] + offset);
    if (@mod(a_nom, det) != 0) return null;

    const b_nom = system[0] * (offset + system[5]) - (offset + system[4]) * system[1];
    if (@mod(b_nom, det) != 0) return null;

    return .{ @divExact(a_nom, det), @divExact(b_nom, det) };
}
fn calcDeterminant(coeffs: []i64) i64 {
    return coeffs[0] * coeffs[3] - coeffs[2] * coeffs[1];
}

fn part1and2(input: []const u8, offset: i64) !i64 {
    // std.debug.print("input:\n{s}\n", .{input});

    var buffer: [64]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const alloc = fba.allocator();

    var it = std.mem.splitScalar(u8, input, '\n');

    var total: i64 = 0;
    // order: a1, a2, b1, b2, X, Y
    // a1 A + b1 B = X
    // a2 A + b2 B = Y
    // det A = a1 * b2 - b1 * a2
    var system = try std.ArrayList(i64).initCapacity(alloc, 6);
    defer system.deinit();
    while (it.next()) |line| {
        if (line.len == 0) {
            defer system.clearRetainingCapacity();
            if (solve(system.items, offset)) |sol| {
                // A * 30 + B * 1 = N tokens
                const token = sol[0] * 3 + sol[1] * 1;
                // std.debug.print("system => {any}\n", .{system.items});
                // std.debug.print("token => (A: {d}, B: {d}) -> {d}\n", .{ sol[0], sol[1], token });
                total += token;
            }
            // std.debug.print("\n", .{});
            continue;
        }
        // std.debug.print("{d}: '{s}'\n", .{ i, line });

        var lineit = std.mem.splitAny(u8, line, " +,=");
        while (lineit.next()) |substr| {
            try system.append(std.fmt.parseInt(i64, substr, 10) catch continue);
        }
        // i += 1;
    }

    return total;
}

test "part 1" {
    const input =
        \\Button A: X+94, Y+34
        \\Button B: X+22, Y+67
        \\Prize: X=8400, Y=5400
        \\
        \\Button A: X+26, Y+66
        \\Button B: X+67, Y+21
        \\Prize: X=12748, Y=12176
        \\
        \\Button A: X+17, Y+86
        \\Button B: X+84, Y+37
        \\Prize: X=7870, Y=6450
        \\
        \\Button A: X+69, Y+23
        \\Button B: X+27, Y+71
        \\Prize: X=18641, Y=10279
        \\
    ;
    try std.testing.expectEqual(480, try part1and2(input, 0));
}

test "part 2" {
    const input =
        \\Button A: X+94, Y+34
        \\Button B: X+22, Y+67
        \\Prize: X=8400, Y=5400
        \\
        \\Button A: X+26, Y+66
        \\Button B: X+67, Y+21
        \\Prize: X=12748, Y=12176
        \\
        \\Button A: X+17, Y+86
        \\Button B: X+84, Y+37
        \\Prize: X=7870, Y=6450
        \\
        \\Button A: X+69, Y+23
        \\Button B: X+27, Y+71
        \\Prize: X=18641, Y=10279
        \\
    ;
    try std.testing.expectEqual(875318608908, try part1and2(input, 10000000000000));
}
