// region _thread:contents
// [1] _thread:spawn_and_join
// [2] _thread:local_storage
// [3] _thread:mutex
// endregion

const std = @import("std");

threadlocal var thread_local_counter: i32 = 100;

var shared_resource: u32 = 0;
var shared_mutex = std.Io.Mutex.init;

pub fn main(init: std.process.Init) !void {
    // region _thread:spawn_and_join
    {
        // 1
        const thread_worker = struct {
            fn run(id: u32, message: []const u8) void {
                std.log.debug("Thread {}: {s}", .{ id, message });
                thread_local_counter += 50;
            }
        };

        const t1 = try std.Thread.spawn(.{}, thread_worker.run, .{ 1, "Hello from worker" });
        const t2 = try std.Thread.spawn(.{}, thread_worker.run, .{ 2, "Parallel computation" });

        // 2
        t1.join();
        t2.join();
    }
    // endregion

    // region _thread:local_storage
    {
        std.log.debug("Main thread local counter: {}", .{thread_local_counter}); // 100
    }
    // endregion

    // region _thread:mutex
    {
        const mutex_worker = struct {
            fn increment(io: std.Io) !void {
                var i: u32 = 0;
                while (i < 1000) : (i += 1) {
                    try shared_mutex.lock(io);
                    defer shared_mutex.unlock(io);

                    shared_resource += 1;
                }
            }
        };

        const t1 = try std.Thread.spawn(.{}, mutex_worker.increment, .{init.io});
        const t2 = try std.Thread.spawn(.{}, mutex_worker.increment, .{init.io});

        t1.join();
        t2.join();

        std.log.debug("Shared resource synchronized value: {}", .{shared_resource}); // 2000
    }
    // endregion

    std.log.info("exit successfully: _thread", .{});
}
