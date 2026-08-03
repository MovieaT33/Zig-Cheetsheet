// region stdlib:contents
// [1] stdlib:allocator
// [2] stdlib:print
// [3] stdlib:array_list
// [4] stdlib:file_system
// endregion

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    // region stdlib:allocator
    {
        const slice = try allocator.alloc(i32, 5);
        defer allocator.free(slice);

        for (slice, 0..) |*item, i|
            item.* = @intCast(i * 10);

        std.log.debug("Allocated array: {any}", .{slice});
    }
    // endregion

    // region stdlib:print
    {
        // 1
        const stdout = std.Io.File.stdout();
        try stdout.writeStreamingAll(io, "Hello from stdout!\n");

        // 2
        const name = "Zig";
        const version = "0.16.0-dev.2905+5d71e3051";

        const formatted_str = try std.fmt.allocPrint(allocator, "Welcome to {s} v{s}!", .{ name, version });
        defer allocator.free(formatted_str);

        std.log.debug("Formatted dynamic string: {s}", .{formatted_str});
    }
    // endregion

    // region stdlib:array_list
    {
        var list = try std.ArrayList(u32).initCapacity(allocator, 0);
        defer list.deinit(allocator);

        try list.append(allocator, 100);
        try list.append(allocator, 200);

        const slice_to_add = [_]u32{ 300, 400, 500 };
        try list.appendSlice(allocator, &slice_to_add);

        std.log.debug("ArrayList length: {}, third element: {}", .{ list.items.len, list.items[2] });
    }
    // endregion

    // region stdlib:file_system
    {
        const filename = "test_stdlib.txt";

        // 1
        const cwd = std.Io.Dir.cwd();

        // 2
        const file = try cwd.createFile(io, filename, .{});
        defer file.close(io);

        // 3
        try file.writeStreamingAll(io, "Zig Standard Library Reference Data\n");

        // 4
        const file_to_read = try cwd.openFile(io, filename, .{});
        defer file_to_read.close(io);

        // 5
        var file_reader = file_to_read.reader(io, &.{});

        const file_content = try file_reader.interface.readAlloc(allocator, 36);
        defer allocator.free(file_content);

        std.log.debug("File successfully read via Reader Interface:\n{s}", .{file_content});

        // 6
        try cwd.deleteFile(io, filename);
    }
    // endregion

    std.log.info("exit successfully: stdlib", .{});
}
