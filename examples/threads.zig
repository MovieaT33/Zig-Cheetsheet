const std = @import("std");

fn worker(idx: usize) void {
    std.debug.print("worker #{}\n", .{idx});
}

test "threading" {
    var threads: [16]std.Thread = undefined;

    inline for (&threads, 0..) |*thread, idx|
        thread.* = try std.Thread.spawn(.{}, worker, .{idx});

    for (threads) |thread|
        thread.join();
}
