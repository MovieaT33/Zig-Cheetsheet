// region function:contents
// [1]  function:declaration
// [2]  function:pub
// [3]  function:recursion
// [4]  function:inline
// [5]  function:noreturn
// [6]  function:struct
// [7]  function:extern
// [8]  function:export
// [9]  function:main
// [10] function:static
// endregion

const std = @import("std");

// region function:declaration
fn add(a: i32, b: i32) i32 {
    return a + b;
}
// endregion

// region function:pub
pub fn publicUtility() void {
    std.log.debug("This function is visible outside this module.", .{});
}
// endregion

// region function:recursion
fn fibonacci(n: u32) u32 {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}
// endregion

// region function:inline
inline fn multiplyByTwo(value: anytype) @TypeOf(value) {
    return value * 2;
}
// endregion

// region function:noreturn
fn crashAndBurn(message: []const u8) noreturn {
    std.debug.panic("Critical error: {s}", .{message});
}
// endregion

// region function:struct
const Counter = struct {
    count: u32,

    fn init() Counter {
        return Counter{ .count = 0 };
    }

    fn increment(self: *Counter) void {
        self.count += 1;
    }

    pub fn getValue(self: *const Counter) u32 {
        return self.count;
    }
};
// endregion

// region function:extern
extern "c" fn abs(x: c_int) c_int;
// endregion

// region function:export
export fn zig_add_for_c(a: c_int, b: c_int) c_int {
    return a + b;
}
// endregion

// region function:static
fn generateId() u32 {
    const Holder = struct {
        var counter: u32 = 0;
    };

    Holder.counter += 1;
    return Holder.counter;
}
// endregion

// region function:main
pub fn main() !void {
    // 1
    _ = add(5, 10);

    // 2
    publicUtility();

    // 3
    _ = fibonacci(6);

    // 4
    _ = multiplyByTwo(@as(u32, 21));

    // 5
    var my_counter = Counter.init();
    my_counter.increment();
    _ = my_counter.getValue();

    // 6
    _ = abs(-42);

    // 7
    if (false)
        crashAndBurn("Something went horribly wrong!");

    // 8
    std.log.debug("IDs: {d}, {d}", .{ generateId(), generateId() });

    std.log.info("exit successfully: function", .{});
}
// endregion
