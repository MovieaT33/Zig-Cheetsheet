const std = @import("std");

pub fn main() !void {
    // region block:if
    {
        _ = if (true) 1 else 0;

        var optional_value: ?u8 = 5;
        if (optional_value) |*value|
            value.* = 10;

        const error_union: anyerror!u8 = 15;
        if (error_union) |success_value| {
            _ = success_value;
        } else |err| _ = err;

        _ = blk: {
            if (false) {
                break :blk @as(i32, 20);
            } else {
                break :blk @as(i32, 25);
            }
        };
    }
    // endregion

    // region block:while
    {
        var i: u8 = 0;
        while (i < 5) : (i += 1) {
            if (i == 2) continue;
            if (i == 4) break;
        }

        var iterator_source: ?u8 = 5;
        while (iterator_source) |value| {
            _ = value;
            iterator_source = null;
        }

        var optional_value: ?u8 = 10;
        while (optional_value) |value| : (optional_value = if (value > 1) value - 1 else null)
            continue;

        var count: u8 = 0;
        _ = blk: while (count < 15) : (count += 1) {
            if (count == 5) break :blk @as(u8, 20);
        } else @as(u8, 25);
    }
    // endregion

    // region block:for
    {
        for (0..10) |i|
            _ = i;

        const items = [_]u8{ 10, 20, 30 };

        for (items, 0..) |item, index| {
            _ = item;
            _ = index;
        }

        var mutable_items = [_]u8{ 1, 2, 3 };
        for (&mutable_items) |*item| {
            item.* *= 2;
        }

        _ = blk: for (items) |item| {
            if (item == 20) break :blk true;
        } else false;
    }
    // endregion

    // region block:for:inline
    {
        const types = .{ i32, f64, bool };

        inline for (types) |T| {
            const size = @sizeOf(T);
            _ = size;
        }
    }
    // endregion

    // region block:label
    {
        const block_value = blk: {
            const a: u32 = 5;
            const b: u32 = 10;
            break :blk a + b;
        };
        _ = block_value;

        outer: while (true) {
            while (true)
                break :outer;
        }
    }
    // endregion

    // region block:switch
    {
        const a: u8 = 2;

        const b: u8 = 10;
        _ = switch (a) {
            0 => @as(u8, 5),
            1, 2 => @as(u8, 10),
            3, b => blk: {
                break :blk @as(u8, 15);
            },
            else => @as(u8, 20),
        };

        _ = blk: switch (a) {
            2 => {
                const c = a * 2;
                break :blk @as(i8, c);
            },
            else => break :blk @as(i8, -1),
        };

        switch (a) {
            0 => return,
            else => {},
        }
    }
    // endregion

    // region block:switch:tagged_union
    {
        const Tag = enum { int, float, text };

        const Payload = union(Tag) {
            int: i32,
            float: f64,
            text: []const u8,
        };

        var value = Payload{ .int = 42 };

        switch (value) {
            .int => |val| _ = val,
            .float => |val| _ = val,
            .text => |val| _ = val,
        }

        const is_numerical = blk: switch (value) {
            .int, .float => break :blk true,
            .text => break :blk false,
        };
        _ = is_numerical;

        switch (value) {
            else => {},
            .int => |*val| val.* += 1,
        }
    }
    // endregion

    // region block:switch:error
    {
        const MyError = error{ ValidationError, NetworkError };
        const res: MyError!u32 = error.ValidationError;

        _ = res catch |err| switch (err) {
            error.ValidationError => @as(u32, 400),
            error.NetworkError => @as(u32, 500),
        };

        if (res) |success_val| {
            _ = success_val;
        } else |err| switch (err) {
            error.ValidationError => {},
            error.NetworkError => {},
        }
    }
    // endregion

    // region block:unreachable
    {
        if (false) {
            const x = true;
            if (!x) unreachable;
        }
    }
    // endregion

    std.debug.print("exit successfully\n", .{});
}
