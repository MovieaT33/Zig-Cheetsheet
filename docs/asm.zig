// region asm:contents
// [1] asm:nop
// [2] asm:addb
// [3] asm:inc
// endregion

const std = @import("std");

pub fn main() !void {
    // region asm:nop
    {
        asm volatile ("nop");
    }
    // endregion

    // region asm:addb
    {
        const a: u8 = 5;
        const b: u8 = 10;

        const c = asm (
            \\ addb %[src2], %[out]
            : [out] "=q" (-> u8),
            : [src1] "0" (a),
              [src2] "q" (b),
        );

        std.log.debug("c = {}", .{c});
    }
    // endregion

    // region asm:inc
    {
        var x: u8 = 5;

        asm volatile (
            \\ inc %[data]
            : [data] "+q" (x),
        );

        std.log.debug("x = {}", .{x});
    }
    // endregion

    std.log.info("exit successfully: asm", .{});
}
