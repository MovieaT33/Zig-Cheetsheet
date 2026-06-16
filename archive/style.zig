// region style:contents
// [1] style:module
// [2] style:type:generic
// [3] style:type:struct
// [4] style:type:error
// [5] style:value:function
// [6] style:value:variable
// endregion

// region style:module
const standard_library = @import("std");
// endregion

// region style:type:generic
fn Box(comptime T: type) type {
    return struct {
        value: T,
    };
}

const IntBox = Box(u8);
const FloatBox = Box(f16);
// endregion

// region style:type:struct
const HttpClient = struct {
    ip: [4]u8,
    port: u16,
};
// endregion

// region style:type:error
const FileError = error{
    FileNotFound,
    AccessDenied,
};
// endregion

// region style:value:function
fn sendRequest() void {}
// endregion

pub fn main() void {
    // region style:variable
    {
        var user_count: u8 = 0;
        const buffer_size = 1024;

        user_count += 1;
        _ = buffer_size;
    }
    // endregion

    standard_library.log.info("exit successfully: style", .{});
}
