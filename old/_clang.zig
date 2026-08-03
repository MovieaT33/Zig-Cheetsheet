// zig run .\docs\_clang.zig -lc

// region _clang:contents
// [1] _clang:import
// [2] _clang:type
// [3] _clang:string
// endregion

const std = @import("std");

// region _clang:import
const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
});
// endregion

pub fn main(init: std.process.Init) !void {
    // region _clang:type
    {
        const c_num: c_int = 42;
        const zig_num: i32 = @intCast(c_num);
        _ = zig_num;

        const negative: c_int = -100;
        const absolute = c.abs(negative);
        std.log.debug("C abs(): {}", .{absolute}); // 100
    }
    // endregion

    // region _clang:string
    {
        // 1
        const c_string = "Hello from Zig via C printf!\n";
        _ = c.printf(c_string);

        // 2
        const zig_str: []const u8 = "Dynamic string";

        const allocator = init.gpa;

        const c_compatible_str = try allocator.dupeZ(u8, zig_str);
        defer allocator.free(c_compatible_str);

        _ = c.printf("Zig dynamic string in C: %s\n", c_compatible_str.ptr);
    }
    // endregion

    std.log.info("exit successfully: _clang", .{});
}
