const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var d: u8 = 1;
    const max_day = 11;
    while (d <= max_day) : (d += 1) {
        const exe = b.addExecutable(.{
            .name = b.fmt("day{:0>2}", .{d}),
            .root_source_file = b.path(b.fmt("day{:0>2}/main.zig", .{d})),
            .target = target,
            .optimize = optimize,
        });

        b.installArtifact(exe);
    }
}
