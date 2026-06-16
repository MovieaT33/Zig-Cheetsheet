const std = @import("std");

pub fn main() !void {
    // region operator
    // [1]  operator:bool
    // [2]  operator:scalar:arithmetic
    // [3]  operator:scalar:saturation
    // [4]  operator:scalar:wrapping
    // [5]  operator:scalar:bitwise
    // [6]  operator:scalar:assignment:arithmetic
    // [7]  operator:scalar:assignment:saturation
    // [8]  operator:scalar:assignment:wrapping
    // [9]  operator:scalar:assignment:bitwise
    // [10] operator:scalar:comparison
    // [11] operator:sequence:indexing
    // [12] operator:sequence:array
    // [13] operator:sequence:vector
    // [14] operator:composite:struct
    // [15] operator:modifier:optional
    // [16] operator:modifier:pointer
    // [17] operator:error
    // endregion

    // region operator:bool
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

    // region operator:scalar:arithmetic
    {
        const a = 5;
        const b = 10;

        _ = -a;
        _ = a + b;
        _ = a - b;
        _ = a * b;
        _ = a / b;
        _ = a % b;
        _ = (a + b) * a;
    }
    // endregion

    // region operator:scalar:saturation
    {
        const a: u8 = 250;
        const b = 10;

        _ = a +| b;
        _ = b -| a;
        _ = a *| b;
        _ = a <<| 1;
    }
    // endregion

    // region operator:scalar:wrapping
    {
        const x: u8 = 254;

        _ = -%x;
        _ = x +% 2;
        _ = x -% 255;
        _ = x *% 2;
    }
    // endregion

    // region operator:scalar:bitwise
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

    // region operator:scalar:assignment:arithmetic
    {
        var x: u8 = 5;

        x += 10;
        x -= 10;
        x *= 10;
        x /= 10;
        x %= 10;
    }
    // endregion

    // region operator:scalar:assignment:saturation
    {
        var x: u8 = 200;

        x +|= 60;
        x -|= 210;
        x *|= 2;
        x <<|= 2;
    }
    // endregion

    // region operator:scalar:assignment:wrapping
    {
        var x: u8 = 5;

        x +%= 10;
        x -%= 10;
        x *%= 10;
    }
    // endregion

    // region operator:scalar:assignment:bitwise
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

    // region operator:scalar:comparison
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

    // region operator:sequence:indexing
    {
        var array = [_]u8{ 1, 2, 3, 4 };
        array[0] = array[1];

        const slice = array[1..3];
        slice[0] = slice[1];
    }
    // endregion

    // region operator:sequence:array
    {
        comptime {
            const a = [_]u8{ 1, 2 };
            const b = [_]u8{ 3, 4 };

            _ = a ++ b;
            _ = a ** 2;
        }
    }
    // endregion

    // region operator:sequence:vector
    {
        const a = @Vector(2, u8){ 1, 2 };
        const b = @Vector(2, u8){ 3, 4 };

        // arithmetic
        _ = a + b;
        _ = b - a;
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

    // region operator:composite:struct
    {
        const Struct = struct {
            x: u8,
            fn action(self: *const @This(), flag: bool) ?@This() {
                if (flag) return null;
                return self.*;
            }
        };

        const instance = Struct{ .x = 10 };
        _ = instance.x;
        _ = instance.action(false);
        _ = Struct.action(&instance, false);
    }
    // endregion

    // region operator:modifier:optional
    {
        const x: ?u8 = 5;

        _ = x == null;
        _ = x != null;

        _ = x.?;
        _ = x orelse unreachable;
    }
    // endregion

    // region operator:modifier:pointer
    {
        var x: u8 = 5;
        const ptr = &x;

        ptr.* = 10;
        _ = ptr.*;
    }
    // endregion

    // region operator:error
    {
        // 1
        const a: anyerror!u8 = 0;

        _ = a catch unreachable;
        _ = a catch |err| return err;

        // 2
        const b = error{One};
        const c = error{Two};
        _ = b || c;
    }
    // endregion

    std.debug.print("exit successfully\n", .{});
}
