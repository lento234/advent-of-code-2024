const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    var d: u8 = 1;
    const max_day = 15;
    while (d <= max_day) : (d += 1) {
        const exe = b.addExecutable(.{
            .name = b.fmt("day{:0>2}", .{d}),
            .root_source_file = b.path(b.fmt("day{:0>2}/main.zig", .{d})),
            .target = target,
            .optimize = .ReleaseFast,
        });

        b.installArtifact(exe);
    }
}
