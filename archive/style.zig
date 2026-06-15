// region style:module
const standard_library = @import("std");
// endregion

// region style:function
fn sendRequest() void {}
// endregion

// region style:generic
fn Box(comptime T: type) type {
    return struct {
        value: T,
    };
}

const IntBox = Box(u8);
// endregion

pub fn main() void {
    // region style:struct
    {
        const HttpClient = struct {
            ip: [4]u8,
            port: u16,
        };

        _ = HttpClient{ .ip = .{ 8, 8, 8, 8 }, .port = 443 };
    }
    // endregion

    // region style:function
    {
        sendRequest();
    }
    // endregion

    // region style:variable
    {
        var user_count: u8 = 0;
        const buffer_size = 1024;

        user_count += 1;
        _ = buffer_size;
    }
    // endregion

    // region style:error
    {
        const FileNotFound = error.FileNotFound;

        standard_library.debug.print("error: {}\n", .{FileNotFound});
    }
    // endregion

    standard_library.debug.print("exit successfully\n", .{});
}
