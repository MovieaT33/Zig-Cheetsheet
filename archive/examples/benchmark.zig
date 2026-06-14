const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var i: u64 = 0;
    const alloc_n = 16;

    while (true) : (i += 1) {
        const data = try allocator.alloc(u64, alloc_n);
        data[0] = 0xF;
        if (i % (1024 * 1024) == 0) {
            std.debug.print("[{}] Size: {} bytes\n", .{ i, 8 * alloc_n * i });
        }
    }
}
