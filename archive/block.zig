const std = @import("std");

pub fn main() !void {
    // region block:if
    {
        // 1
        _ = if (true) true else false;

        // 2
        const a = 5;
        const b = 10;
        _ = if (a > b) {
            const c = a;
            c;
        } else if (a == 20)
            30
        else if (a < b)
            b
        else
            0;

        // 3
        var optional_value: ?u8 = 5;
        if (optional_value) |*value| {
            if (value.* > 0)
                value.* -= 1;
        }

        _ = if (optional_value) |value| value else 0;

        // 4
        const error_union: anyerror!u8 = 5;
        if (error_union) |success_value| {
            _ = success_value;
        } else |err| _ = err;

        // 5
        _ = blk: {
            if (false) {
                break :blk @as(u8, 5);
            } else {
                break :blk @as(u8, 10);
            }
        };
    }
    // endregion

    // region block:while
    {
        // 1
        while (false) {
            break;
        }

        // 2
        var i: u8 = 0;
        while (i < 5) : (i += 1) {
            if (i == 2) continue;
            if (i == 4) break;
        }

        // 3
        var iterator_source: ?u8 = 5;
        while (iterator_source) |*value| {
            if (value.* == 0) break;
            // value.* = null; // XXX: expected type 'u8', found '@TypeOf(null)'
            value.* -= 1;
        }

        // 4
        var optional_value: ?u8 = 10;
        while (optional_value) |value| : (optional_value = if (value > 1) value - 1 else null)
            continue;

        // 5
        var count: u8 = 0;
        _ = blk: while (count < 15) : (count += 1) {
            if (count == 5) break :blk @as(u8, 20);
        } else @as(u8, 25);

        // 6
        var error_source: anyerror!u8 = 10;
        while (error_source) |value| {
            _ = value;
            error_source = error.SomeError;
        } else |err| {
            std.debug.print("error: {}\n", .{err});
        }

        // 7
        comptime var inline_i = 0;
        inline while (inline_i < 3) : (inline_i += 1) {
            continue;
        }
    }
    // endregion

    // region block:for
    {
        // 1
        for (0..10) |_|
            continue;

        // 2
        const items = [_]u8{ 1, 2, 3 };

        for (items, 0..) |item, index| {
            _ = item;
            _ = index;
        }

        // 3
        var mutable_items = [_]u8{ 1, 2, 3 };
        for (&mutable_items) |*item| {
            item.* *= 2;
        }

        // 4
        _ = blk: for (items) |item| {
            if (item == 20) break :blk true;
        } else false;

        // 5
        const User = struct { id: u32, active: bool };
        var users = [_]User{
            .{ .id = 1, .active = true },
            .{ .id = 2, .active = false },
        };

        for (&users) |*user| {
            if (!user.active)
                user.active = true;
        }

        // 6
        const maybe_numbers = [_]?u8{ 10, null, 30 };
        for (maybe_numbers) |maybe_num| {
            if (maybe_num) |num|
                _ = num;
        }

        // 7
        const ResultError = error{ Overflow, InvalidData };
        const results = [_]ResultError!u8{ 5, ResultError.Overflow, 25 };

        for (results) |res| {
            const value = res catch 0;
            _ = value;

            if (res) |success_value| {
                _ = success_value;
            } else |err| {
                std.debug.print("error: {}\n", .{err});
            }
        }

        // 8
        const ids = [_]u8{ 101, 102, 103 };
        const scores = [_]u8{ 85, 92, 78 };
        for (ids, scores) |id, score| {
            _ = id;
            _ = score;
        }

        // 9
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
