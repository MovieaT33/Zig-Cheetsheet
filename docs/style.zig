//! Top-level
//! documentation comment

// line
// comment

test "quoted-identifier" {
    const @"u8": u8 = 0;
    _ = @"u8";
}

test "variable & constant" {
    var user_count: u8 = 0;
    const buffer_size = 1024;

    user_count += 1;
    _ = buffer_size;
}

/// module: (documentation
///          comment)
const standard_library = @import("std");
const Io = @import("std").Io;

test "type" {
    // generic:
    {
        const Box = struct {
            fn Box(comptime T: type) type {
                return struct {
                    value: T,
                };
            }
        };
        _ = Box;
    }

    // error set:
    {
        const FileError = error{
            FileNotFound,
            AccessDenied,
        };
        _ = FileError;
    }

    // composite:
    {
        const Timestamp = struct {
            /// The number of seconds since the Unix epoch.
            seconds: u64,
        };
        _ = Timestamp;
    }
}

test "block" {
    _ = blk_label: {
        break :blk_label;
    };
}

test "function" {
    _ = struct {
        fn sendRequest() void {}
    };
}
