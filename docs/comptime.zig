// region comptime:contents
// [1] comptime:basic
// [2] comptime:variable
// [3] comptime:block
// [4] comptime:if
// [5] comptime:for:inline
// [6] comptime:while:inline
// [7] comptime:switch
// [8] comptime:parameter
// [9] comptime:generic
// endregion

const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    // region comptime:basic
    {
        comptime {
            // 1
            const ptr_size = @sizeOf(*anyopaque);
            if (ptr_size != 8)
                @compileError("This library requires a 64-bit architecture!");

            // 2
            const max_connections: u32 = 100;
            if (max_connections > 1000)
                @compileError("Security risk: max_connections cannot exceed 1000");
        }
    }
    // endregion

    // region comptime:variable
    {
        comptime var compile_time_var: u32 = 0;

        inline for (0..5) |_| {
            compile_time_var += 10;
        }

        std.log.debug("Comptime var: {}", .{compile_time_var}); // 50
    }
    // endregion

    // region comptime:block
    {
        const precomputed_factorials = comptime blk: {
            var table: [6]u64 = undefined;
            table[0] = 1;
            var i: usize = 1;
            while (i < 6) : (i += 1) {
                table[i] = table[i - 1] * i;
            }
            break :blk table;
        };

        std.log.debug("Precomputed factorial: {}", .{precomputed_factorials[5]}); // 120
    }
    // endregion

    // region comptime:if
    {
        // 1
        if (builtin.os.tag == .windows) {
            std.log.debug("Windows target system active", .{});
        } else std.log.debug("Non-Windows target system active", .{});

        // 2
        const is_debug = (builtin.mode == .Debug);
        if (comptime is_debug) {
            std.log.info("[DEBUG-ONLY] Structural diagnostics armed.", .{});
        } else {
            std.log.info("[RELEASE-ONLY] Running optimized code.", .{});
        }
    }
    // endregion

    // region comptime:for:inline
    {
        const types = .{ i32, f64, bool };

        inline for (types, 0..) |T, index| {
            const size = @sizeOf(T);
            std.log.debug("Type at index {} is {s} (size: {} bytes)", .{ index, @typeName(T), size });
        }
    }
    // endregion

    // region comptime:while:inline
    {
        comptime var state_counter = 0;

        inline while (state_counter < 3) : (state_counter += 1) {
            std.log.debug("Unrolled while loop iteration: {}", .{state_counter});
        }
    }
    // endregion

    // region comptime:switch
    {
        const current_arch = builtin.cpu.arch;

        const word_size = comptime switch (current_arch) {
            .x86_64, .aarch64 => @as(u8, 64),
            .x86, .arm => @as(u8, 32),
            else => @as(u8, 0),
        };

        std.log.debug("Target CPU Word Size: {} bits", .{word_size});
    }
    // endregion

    // region comptime:parameter
    {
        const math_utils = struct {
            fn power(base: u32, exp: u32) u32 {
                var res: u32 = 1;
                var i: u32 = 0;
                while (i < exp) : (i += 1) res *= base;
                return res;
            }
        };

        const static_power = comptime math_utils.power(2, 10);
        std.log.debug("Evaluated at compile-time (2^10): {}", .{static_power}); // 1024
    }
    // endregion

    // region comptime:generic
    {
        const GenericContainer = struct {
            fn Box(comptime T: type) type {
                return struct {
                    value: T,

                    fn printPayloadType(self: @This()) void {
                        _ = self;
                        std.log.debug("Box type name: {s}", .{@typeName(T)});
                    }
                };
            }
        };

        const IntBox = GenericContainer.Box(i32);
        var my_int_box: IntBox = .{ .value = 5 };
        my_int_box.printPayloadType(); // i32
    }
    // endregion

    std.log.info("exit successfully: comptime", .{});
}
