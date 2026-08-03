const std = @import("std");

test "unreachable" {
    if (false)
        unreachable;
}

test "block" {
    {
        const a: u8 = 0;
        _ = a;
    }
}

test "block.label" {
    const a: u8 = blk: {
        const b = 1;
        const c: u8 = 2;

        break :blk b + c;
    };
    _ = a;
}

test "block.defer" {
    var a: u8 = 0;
    _ = {
        defer a = 2;
        defer {
            a = 3;
            a = 4;
        }
        a = 1;
    };
    std.debug.print("{}\n", .{a}); // 2
}

test "block.errdefer" {
    const a = struct {
        var b = false;

        fn c(d: bool) !void {
            errdefer @This().b = true;
            errdefer {
                @This().b = true;
                @This().b = false;
            }

            if (d) return error.SkipZigTest;
        }
    };

    a.c(true) catch {};
    std.debug.print("{}\n", .{a.b}); // true
}

test "if" {
    const a: void = if (false) true;
    const b =
        if (false)
            true
        else if (true)
            false;
    const c =
        if (false)
            true
        else
            false;
    const d =
        if (false)
            true
        else if (true)
            false
        else
            false;

    if (false) {}
    if (false) {} else if (true) {}
    if (false) {} else {}
    if (false) {} else if (true) {} else {}

    _ = a;
    _ = b;
    _ = c;
    _ = d;
}

test "if.error" {
    const a: anyerror!u8 = 2;
    if (a) |x| {
        _ = x;
    } else |y| _ = y;
}

test "if.optional" {
    var a: ?u8 = 1;
    if (a) |*x| {
        if (x.* > 0)
            x.* -= 1;
    } else |y| _ = y;
}

test "while" {
    _ = while (false) true;
    _ = while (false) true else false;

    var a: u8 = 0;
    while (a < 5) : (a += 1) {
        if (a == 2) continue;
        if (a == 4) break;
    }

    comptime var b = 0;
    inline while (b < 3) : (b += 1)
        continue;
}

test "while.label" {
    outer: while (true) {
        while (false)
            continue :outer;
        break :outer;
    }
}

test "while.error" {
    var a: anyerror!u8 = 10;
    while (a) |x| {
        _ = x;
        a = error.SkipZigTest;
    } else |y| {
        std.log.err("{}", .{y});
    }
}

test "while.optional" {
    var a: ?u8 = 1;
    while (a) |*x| {
        if (x.* == 0) break;
        // XXX: expected type 'u8', found '@TypeOf(null)':
        // value.* = null;
        x.* -= 1;
    }

    const b: ?u8 = 2;
    while (b) |x| : (x = if (x) x - 1 else null)
        continue;
}

test "for" {
    for (0..2) |_|
        break;

    for (0..2) |_|
        continue;

    const a = [_]u8{ 0, 1, 2 };

    for (a, 0..) |x, y| {
        _ = x;
        _ = y;
    }

    var b = [_]u8{ 3, 4, 5 };
    for (&b) |*x|
        x.* *= 2;

    _ = blk: for (a) |x| {
        if (x == 1) break :blk true;
    } else false;

    const User = struct { id: u32, active: bool };
    var users = [_]User{
        .{ .id = 1, .active = true },
        .{ .id = 2, .active = false },
    };

    for (&users) |*user| {
        if (!user.active)
            user.active = true;
    }

    const maybe_numbers = [_]?u8{ 10, null, 30 };
    for (maybe_numbers) |maybe_num| {
        if (maybe_num) |num|
            _ = num;
    }

    const ResultError = error{ Overflow, InvalidData };
    const results = [_]ResultError!u8{ 5, ResultError.Overflow, 25 };

    for (results) |res| {
        const value = res catch 0;
        _ = value;

        if (res) |success_value| {
            _ = success_value;
        } else |err| {
            std.log.err("{}", .{err});
        }
    }

    const ids = [_]u8{ 101, 102, 103 };
    const scores = [_]u8{ 85, 92, 78 };
    for (ids, scores) |id, score| {
        _ = id;
        _ = score;
    }

    const types = .{ i32, f64, bool };

    inline for (types) |T| {
        const size = @sizeOf(T);
        _ = size;
    }
}

test "for.label" {
    _ = outer: for (0..4) |_| {
        for (0..4) |_|
            break :outer;
    };
}

test "switch" {
    const a: u8 = 1;
    const b = 2;

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

    const Tag = enum {
        int,
        float,
        text,
    };

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

test "switch.label" {}

test "switch.catch" {}
