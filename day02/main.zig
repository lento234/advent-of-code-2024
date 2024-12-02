const std = @import("std");

fn intFromStr(comptime T: type, str: []const u8) !T {
    return std.fmt.parseInt(T, str, 10);
}

fn isSafe(line: []const u8, max_change: u32) !bool {
    var splits = std.mem.tokenizeScalar(u8, line, ' ');

    var l = try intFromStr(i32, splits.next().?);
    var check_direction = true;
    var increasing = true;
    while (splits.next()) |r_str| {
        const r = try intFromStr(i32, r_str);
        if (check_direction and (r - l) < 0) {
            increasing = false;
            check_direction = false;
        }
        if (increasing and ((r - l) > max_change or r < l or r == l)) {
            std.debug.print("increasing: {d}, {d}\n", .{ r, l });
            return false;
        } else if (!increasing and ((l - r) > max_change or r > l or r == l)) {
            std.debug.print("decreasing: {d}, {d}\n", .{ r, l });
            return false;
        }
        l = r;
    }
    return true;
}

fn part1(input: []const u8) !u32 {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var n_safe: u32 = 0;
    while (lines.next()) |line| {
        std.debug.print("line -> {s}\n", .{line});

        if (try isSafe(line, 3)) {
            n_safe += 1;
        }
    }
    return n_safe;
}

pub fn main() !void {
    // const input = std.fs.cwd().readFileAlloc()
}

test "part 1" {
    const input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;

    try std.testing.expectEqual(2, try part1(input));
}
