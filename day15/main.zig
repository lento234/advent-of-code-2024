const std = @import("std");

fn part1(input: []const u8) !void {
    std.debug.print("input:\n{s}\n", .{input});

    const idx = std.mem.indexOf(u8, input, "\n\n");
    std.debug.print("idx => {any}\n", .{idx});
    if (idx) |mid| {
        std.debug.print("input:\n{s}\n", .{input[0..mid]});
        std.debug.print("input:\n{s}\n", .{input[mid + 1 ..]});
    }
}

test "part 1" {
    const alloc = std.testing.allocator;

    const input = try std.fs.cwd().readFileAlloc(alloc, "test_input.txt", 1 << 15);
    defer alloc.free(input);

    try part1(input);
}
