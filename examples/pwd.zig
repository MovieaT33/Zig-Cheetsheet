const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var path_buffer: [std.fs.max_path_bytes]u8 = undefined;
    const bytes_written = try std.process.currentPath(io, &path_buffer);
    const cwd = path_buffer[0..bytes_written];

    std.debug.print("{s}\n", .{cwd});
}
