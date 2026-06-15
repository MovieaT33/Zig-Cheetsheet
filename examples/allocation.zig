const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const data = try allocator.alloc(u8, 64);
    defer allocator.free(data);
    data[0] = 10;
    for (data) |value|
        std.debug.print("{}\n", .{value});
}
