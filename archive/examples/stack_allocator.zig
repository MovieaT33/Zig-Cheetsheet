const std = @import("std");

inline fn push(val: u64) void {
    asm volatile (
        \\ push %[v]
        :
        : [v] "r" (val),
        : .{ .memory = true });
}

inline fn pop() u64 {
    return asm volatile (
        \\ pop %[res]
        : [res] "={rax}" (-> u64),
        :
        : .{ .memory = true });
}

pub fn main() void {
    std.debug.print("Stack allocator example\n", .{});
    push(10);
    const x: u64 = pop();
    std.debug.print("x: {}\n", .{x});

    // const res: u8 = test_func(); // Segmentation fault at address 0x14: aborting due to recursive panic
    // std.debug.print("res: {}\n", .{res});

    // std.debug.print("Pushed - OK", .{});

    // for (0..5) |i| {
    //     const val = pop();
    //     std.debug.print("[{}] {}", .{ i, val });
    // }
}

fn test_func() u8 {
    push(10);
    push(20);
    return 30;
}
