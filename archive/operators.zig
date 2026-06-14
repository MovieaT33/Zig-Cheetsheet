const std = @import("std");

pub fn main() !void {
    // region operators:bool:logical
    {
        const a = true;
        const b = false;

        _ = !a;
        _ = a == b;
        _ = a != b;
        _ = a and b;
        _ = a or b;
    }
    // endregion

    // region operators:scalar:arithmetic
    {
        const a = 5;
        const b = 10;

        _ = -a;
        _ = a + b;
        _ = a - b;
        _ = a * b;
        _ = a / b;
        _ = a % b;
    }
    // endregion

    // region operators:scalar:saturation
    {
        const a: u8 = 250;
        const b = 10;

        _ = a +| b;
        _ = b -| a;
        _ = a *| b;
        _ = a <<| 1;
    }
    // endregion

    // region operators:scalar:wrapping
    {
        const x: u8 = 254;

        _ = -%x;
        _ = x +% 2;
        _ = x -% 255;
        _ = x *% 2;
    }
    // endregion

    // region operators:scalar:comparison
    {
        const a = 5;
        const b = 10;

        _ = a == b;
        _ = a != b;
        _ = a < b;
        _ = a > b;
        _ = a <= b;
        _ = a >= b;
    }
    // endregion

    // region operators:scalar:bitwise
    {
        const a: u8 = 0b1010_1010;
        const b = 0b1100_1100;

        _ = ~a;
        _ = a & b;
        _ = a | b;
        _ = a ^ b;
        _ = a << 1;
        _ = a >> 1;
    }
    // endregion

    // region operators:scalar:assignment:arithmetic
    {
        var x: u8 = 5;

        x += 10;
        x -= 10;
        x *= 10;
        x /= 10;
        x %= 10;
    }
    // endregion

    // region operators:scalar:assignment:saturation
    {
        var x: u8 = 200;

        x +|= 60;
        x -|= 210;
        x *|= 2;
        x <<|= 2;
    }
    // endregion

    // region operators:scalar:assignment:wrapping
    {
        var x: u8 = 5;

        x +%= 10;
        x -%= 10;
        x *%= 10;
    }
    // endregion

    // region operators:scalar:assignment:bitwise
    {
        var a: u8 = 0b1010_1010;
        const b = 0b1100_1100;

        a &= b;
        a |= b;
        a ^= b;
        a <<= 1;
        a >>= 1;
    }
    // endregion

    // region operators:pointer
    {
        var x: u8 = 5;
        const ptr = &x;

        ptr.* = 10;
        _ = ptr.*;
    }
    // endregion

    // region operators:indexing
    {
        var a = [_]u8{ 1, 2 };
        a[0] = a[1];

        var b = [_]u8{ 3, 4, 5, 6 };
        const c = b[1..3];
        c[0] = c[1];
    }
    // endregion

    // region operators:array
    {
        comptime {
            const a = [_]u8{ 1, 2 };
            const b = [_]u8{ 3, 4 };

            _ = a ++ b;
            _ = a ** 2;
        }
    }
    // endregion

    // region operators:vector
    {
        const Vec2 = @Vector(2, u8);
        const a = @Vector(2, u8){ 3, 4 };
        const b: Vec2 = .{ 1, 2 };

        _ = a + b;
        _ = a - b;
        _ = a * b;
        _ = a / b;
        _ = a % b;

        _ = a +| b;
        _ = a -| b;
        _ = a *| b;

        _ = a +% b;
        _ = a -% b;
        _ = a *% b;

        _ = a == b;
        _ = a != b;
        _ = a < b;
        _ = a > b;
        _ = a <= b;
        _ = a >= b;
    }
    // endregion

    // region operators:optional
    {
        const x: ?u8 = 42;

        _ = x == null;
        _ = x != null;
        _ = x.?;
        _ = x orelse unreachable;
    }
    // endregion

    // region operators:catch
    {
        const x: anyerror!u8 = 0;

        _ = x catch unreachable;
        _ = x catch |err| return err;
    }
    // endregion

    // region operators:struct
    {
        const LocalStruct = struct {
            x: u8,
            fn action() void {}
        };

        const instance = LocalStruct{ .x = 10 };
        _ = instance.x;
        LocalStruct.action();
    }
    // endregion

    // region operators:error
    {
        const error_union = anyerror!u8;
        _ = error_union;

        const a = error{One};
        const b = error{Two};
        const c = a || b;
        _ = c;
    }
    // endregion

    std.debug.print("exit successfully\n", .{});
}
