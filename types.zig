//! Top-level
//! documentation comment

/// Documentation
/// comment
const std = @import("std"); // global line comment: order is ignored

pub fn main() !void {
    // local line comment

    // region types:qualifiers
    var mutable: u8 = 0b1;
    const immutable: u8 = 0o7;
    const volatile_ptr: *u8 = &mutable;

    mutable = 0xF;
    _ = immutable;
    _ = volatile_ptr;
    // endregion

    // region types:as:local
    var int = @as(u8, 0);
    const float = @as(f16, 3.14);

    int = 0;
    _ = float;
    // endregion

    // region types:type
    {
        const x = u8;
        _ = x;
    }
    // endregion

    // region types:comptime:undefined:local
    const inferred_undefined = undefined;

    _ = inferred_undefined;
    // endregion

    // region types:scalar:undefined:local
    var explicit_undefined: u8 = undefined; // garbage

    explicit_undefined = 0;
    // endregion

    // region types:comptime:scalar:integer:local
    const inferred_comptime_integer = 0;
    const explicit_comptime_integer: comptime_int = 0;

    _ = inferred_comptime_integer;
    _ = explicit_comptime_integer;
    // endregion

    // region types:comptime:scalar:float:local
    const inferred_comptime_float = 0;
    const explicit_comptime_float: comptime_float = 0.0;

    _ = inferred_comptime_float;
    _ = explicit_comptime_float;
    // endregion

    // region types:scalar:boolean:local
    var inferred_flag = false;
    const explicit_flag: bool = true;

    inferred_flag = true;
    _ = explicit_flag;
    // endregion

    // region types:scalar:integer:local
    const zero: u8 = 0.0;
    // var non_zero: u8 = -3.14; // XXX: fractional component prevents float value '-3.14' from coercion to type 'u8'

    _ = zero;
    // _ = non_zero;
    // endregion

    // region types:scalar:integer:unsigned:local
    const custom_u1_max: u1 = 1;
    const u8_max: u8 = 255;
    const u16_max: u16 = 65_535;
    const u32_max: u32 = 4_294_967_295;
    const u64_max: u64 = 18_446_744_073_709_551_615;
    const u128_max: u128 = 340_282_366_920_938_463_463_374_607_431_768_211_455;
    var custom_u65535_max: u65535 = undefined;

    _ = custom_u1_max;
    _ = u8_max;
    _ = u16_max;
    _ = u32_max;
    _ = u64_max;
    _ = u128_max;
    custom_u65535_max = 0;
    // endregion

    // region types:scalar:integer:signed:local
    const custom_i1_min: i1 = -1;
    const i8_min: i8 = -128;
    const i16_min: i16 = -32_768;
    const i32_min: i32 = -2_147_483_648;
    const i64_min: i64 = -9_223_372_036_854_775_808;
    const i128_min: i128 = -170_141_183_460_469_231_731_687_303_715_884_105_728;
    var custom_i65535_min: i65535 = undefined;

    _ = custom_i1_min;
    _ = i8_min;
    _ = i16_min;
    _ = i32_min;
    _ = i64_min;
    _ = i128_min;
    custom_i65535_min = 0;
    // endregion

    // region types:scalar:integer:architecture:local
    var unsigned_size: usize = 123;
    const signed_size: isize = -123;

    unsigned_size = 0;
    _ = signed_size;
    // endregion

    // region types:scalar:float:local
    var f16_size: f16 = undefined;
    const f32_size: f32 = 4.0;
    const f64_size: f64 = f32_size * 2;
    const f80_size: f80 = 10.0;
    const f128_size: f128 = 16.0;

    f16_size = 2;
    _ = f64_size;
    _ = f80_size;
    _ = f128_size;
    // endregion

    // region types:scalar:vector
    const Vec4 = @Vector(4, f32);

    var a: Vec4 = .{ 1, 2, 3, 4 };
    a[0] = 0;
    const b: Vec4 = .{ a[3], 20, 30, 40 };
    const c = a * b;
    const arr: [4]f32 = c;
    std.debug.print("{any}\n", .{arr});
    // endregion

    // region types:comptime:constructor:optional:local
    const immutable_optional = null;

    _ = immutable_optional;
    // endregion

    // region types:constructor:optional:local
    var mutable_optional: ?u8 = null;

    mutable_optional = 0;
    // endregion

    // region types:array:local
    var mutable_array = [_]u16{ 0, 1, 2, 3 };
    const immutable_array: [4]u8 = .{
        @as(u8, @truncate(mutable_array[3])) + 1,
        5,
        6,
        7,
    };

    const last_idx = mutable_array.len - 1;
    mutable_array[last_idx] = 3000;
    const last_value = mutable_array[last_idx];
    std.debug.print("{}\n", .{last_value}); // 3000
    _ = immutable_array;
    // endregion

    // region types:scalar:char:local
    var mutable_char: u8 = 'a'; // 97
    const immutable_char: u32 = '🔥'; // 128293

    mutable_char = @truncate(immutable_char);
    // endregion

    // region types:array:str:local
    const inferred_str = "Inferred string";
    const explicit_str: [:0]const u8 = "Explicit string";
    const c_str = [_]u8{ 65, 'r', 'c', 'h', ' ', 'b', inferred_str[9], 'w' };

    _ = explicit_str;
    _ = c_str;
    // endregion

    // region scalar:array:slice:local
    var full_slice: []u16 = &mutable_array;
    const one = 1;
    var slice = full_slice[one..3]; // {1, 2}

    std.debug.print("{}\n", .{full_slice[0]}); // 0
    std.debug.print("{}\n", .{full_slice.len}); // 4

    std.debug.print("{}\n", .{slice[0]}); // 1
    std.debug.print("{}\n", .{slice.len}); // 2
    // endregion

    // region types:constructor:pointer:local
    var foo: i32 = undefined;
    const ptr_to_foo: *i32 = &foo;
    ptr_to_foo.* = 10; // foo = 10;

    const ptr_to_ptr: *const *i32 = &ptr_to_foo;
    ptr_to_ptr.*.* = 200; // foo = 200;
    // endregion

    // region types:constructor:pointer:array:local
    const ptr_to_array = &mutable_array[0];
    std.debug.print("{}\n", .{ptr_to_array.*}); // 0
    // endregion

    // region types:constructor:pointer:slice:local
    const ptr_to_slice = &slice[0];
    ptr_to_slice.* = 40000;
    std.debug.print("{}\n", .{mutable_array[1]}); // 40000
    // endregion

    // region types:composite:struct:unpacked:local
    const Point = struct {
        x: i32 = 0,
        y: i32 align(32),

        const DEFAULT_DELTA: i32 = 64;

        pub fn moveX(self: *@This(), delta: ?i32) void {
            self.x += delta orelse DEFAULT_DELTA;
        }
    };
    const Vector: type = struct { values: []i32, len: usize };

    var mutable_point: Point = .{ .y = 4 };
    const immutable_point = Point{ .x = 8, .y = @field(mutable_point, "y") * 4 };

    mutable_point.x = 32;
    mutable_point.moveX(null);
    std.debug.print("{}\n", .{mutable_point.x}); // 96
    std.debug.print("{}\n", .{immutable_point.y}); // 16
    _ = Vector;
    // endregion

    // region types:composite:struct:packed:local
    const inferred_Byte = packed struct {
        a: u4,
        b: u4,
    };
    const explicit_Byte: type = packed struct {
        c: u8,
    };

    _ = inferred_Byte;
    _ = explicit_Byte;
    // endregion

    // region types:composite:enum:local
    const inferred_Color = enum {
        red,
        green,
        blue,
    };
    const explicit_State: type = enum(u8) { idle, running, paused, stopped };

    var color: inferred_Color = .red;
    color = .green;
    const color_int: u8 = @intFromEnum(color);
    const color_back: inferred_Color = @enumFromInt(color_int);

    const state = .idle;

    _ = explicit_State;
    _ = color_back;
    _ = state;
    // endregion

    // region types:composite:union:untagged:local
    const inferred_Value = union {
        int: i32,
        float: f32,
    };
    const explicit_Value: type = union {
        int: i32,
        float: f32,
    };

    var value: inferred_Value = .{ .int = 10 };
    value = .{ .float = 3.14 };
    value.int = 200;
    _ = explicit_Value;
    // endregion

    // region types:composite:union:tagged:local
    const inferred_TaggedValue = union(enum) {
        int: i32,
        float: f32,
    };
    const explicit_TaggedValue1: type = union(enum(i8)) {
        int: i32,
        float: f32,
    };
    const Value_Tag = enum {
        int,
        float,
    };
    const explicit_TaggedValue2: type = union(Value_Tag) {
        int: i32,
        float: f32,
    };

    var tagged_value: inferred_TaggedValue = .{ .int = 10 };

    switch (tagged_value) {
        .int => |*i| i.* = 200,
        .float => {},
    }

    _ = explicit_TaggedValue1;
    _ = explicit_TaggedValue2;
    // endregion

    // region types:anytype:local
    print_value(10);
    print_value(3.14);
    // endregion

    // region types:constructor:error:local
    try open_file(false);
    // region types:void:local
    const result: void = open_file(false) catch |err| {
        return err;
    };
    // endregion
    _ = result;
    // endregion

    // region types:comptime:type:local
    _ = try alloc(u8, 2);
    inspect(u8);
    // endregion
}

// region types:void:global
inline fn bar() void {}
// endregion

// region types:constructor:error:global
inline fn open_file(is_testing: bool) FileError!void {
    if (is_testing) return FileError.Test;
}

inline fn close_file() anyerror!void {
    return error.NotFound;
}

const FileError = error{
    NotFound,
    AccessDenied,
    Test,
};
// endregion

// region types:anytype:global
inline fn print_value(x: anytype) void {
    std.debug.print("{}\n", .{x});
}
// endregion

// region types:comptime:type:global
fn alloc(comptime T: type, len: usize) ![]T {
    const allocator = std.heap.page_allocator;
    return try allocator.alloc(T, len);
}

fn inspect(comptime T: type) void {
    const info = @typeInfo(T);

    switch (info) {
        .int => |i| {
            std.debug.print("int bits={}\n", .{i.bits});
        },
        .float => |f| {
            std.debug.print("float bits={}\n", .{f.bits});
        },
        .@"struct" => {
            std.debug.print("struct\n", .{});
        },
        .pointer => {
            std.debug.print("pointer\n", .{});
        },
        else => {
            std.debug.print("other\n", .{});
        },
    }
}
// endregion

// TODO: anonymous / noreturn /return / циклічні / comptime x = / atomic / pub/priv / function / `\\`
