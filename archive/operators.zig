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
        var array = [_]u8{ 1, 2, 3, 4 };
        array[0] = array[1];

        const slice = array[1..3];
        slice[0] = slice[1];
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
        const a = @Vector(2, u8){ 3, 4 };
        const b = @Vector(2, u8){ 1, 2 };

        // arithmetic
        _ = a + b;
        _ = a - b;
        _ = a * b;
        _ = a / b;
        _ = a % b;

        // saturation
        _ = a +| b;
        _ = a -| b;
        _ = a *| b;

        // wrapping
        _ = a +% b;
        _ = a -% b;
        _ = a *% b;

        // comparison
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

    // region operators:struct
    {
        const Struct = struct {
            x: u8,
            fn action() void {}
        };

        const instance = Struct{ .x = 10 };
        _ = instance.x;
        Struct.action();
    }
    // endregion

    // region operators:catch
    {
        const x: anyerror!u8 = 0;

        _ = x catch unreachable;
        _ = x catch |err| return err;
    }
    // endregion

    // region operators:error
    {
        const error_union = anyerror!u8;
        _ = error_union;

        const a = error{One};
        const b = error{Two};
        _ = a || b;
    }
    // endregion

    std.debug.print("exit successfully\n", .{});
}
