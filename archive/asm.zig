const std = @import("std");

pub fn main() void {
    // region asm
    {
        asm volatile ("nop");

        const a: u32 = 10;
        const b: u32 = 20;
        _ = asm (
            \\ add %[out], %[src1], %[src2]
            : [out] "=r" (-> u32),
            : [src1] "r" (a),
              [src2] "r" (b),
        );
    }
    // endregion

    std.debug.print("exit successfully\n", .{});
}
