// region async:contents
// [1] async:status
// endregion

const std = @import("std");

pub fn main() !void {
    // region async:status
    {
        // NOTE: Async/Await functionality is currently being redesigned and
        // is temporarily unavailable in the self-hosted compiler backend.
        // It will be reintroduced once the language specification stabilizes.

        std.log.info("async/await status: work in progress", .{});
    }
    // endregion

    std.log.info("exit successfully: async", .{});
}
