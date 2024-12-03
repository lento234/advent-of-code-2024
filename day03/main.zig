const std = @import("std");

fn part1(input: []const u8) !i32 {
    std.debug.print("input: {s}\n", .{input});
    var idx: usize = 0;
    while (idx < input.len - 4) {
        if (input[idx] == 'm' and input[idx + 1] == 'u' and input[idx + 2] == 'l' and input[idx + 3] == '(') {
            var k = idx;
            while (k < input.len) {
                if (input[k] == ')') {
                    break;
                }
                k += 1;
            }
            if (input[k] != ')') {
                continue;
            }
            std.debug.print("start {}, end {}\n", .{ idx, k });
        }
        idx += 1;
    }
    return 0;
}

test "part1" {
    const input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";

    try std.testing.expectEqual(161, try part1(input));
}
