const std = @import("std");

/// export.variable (runtime)
export var exported_var: u8 = 0;

/// export.function (runtime)
export fn exportedFn() void {}

/// extern.variable
extern var external_var: u8;

/// extern.function (runtime)
extern fn externalFn() void;

/// extern.structure
const ExternStruct = extern struct {
    x: u8,
    y: u32,
};

/// extern.union
const ExternUnion = extern union {
    x: u32,
    y: f32,
};

/// scope.file
const global_var = 0;

test "scope.block" {
    const local_var = 0;
    _ = local_var;
}

test "discard" {
    const expression = 0;
    _ = expression;
}

test "value" {
    // undefined:
    {
        const a: u8 = undefined;
        const b = undefined;
        const c: @TypeOf(undefined) = undefined;

        const _d = struct {
            fn e() void {
                return undefined;
            }
        };

        _ = a;
        _ = b;
        _ = c;
        _ = _d;
    }

    // type (compile-time):
    {
        const a = type;
        const b: type = type;

        const c = u8;
        const d: type = u8;
        const _e: d = 0;
        const _f = struct {
            fn g() type {}

            fn h() d {}
        };

        _ = a;
        _ = b;
        _ = c;
        _ = _e;
        _ = _f;
    }

    // void:
    {
        const a = {};
        const b: void = {};

        _ = a;
        _ = b;
    }

    // tensor.scalar.boolean:
    {
        const a = true;
        const b: bool = false;

        _ = a;
        _ = b;
    }

    // tensor.scalar.compile-time.integer:
    {
        const a = 0;
        const b: comptime_int = 0b0_1 + 0o0_7 + 0x0_f + 9_0e+0_1 + 0.0 + '🔥';

        _ = a;
        _ = b;
    }

    // tensor.scalar.compile-time.float:
    {
        const a = 1.0E-0_1 + 0x.fp+0_1 + 0xF.FP-0_1;
        const b: comptime_float = 0;

        _ = a;
        _ = b;
    }

    // tensor.scalar.integer:
    {
        const custom_u1_max: u1 = 1;
        const u8_max: u8 = 255;
        const u16_max: u16 = 65_535;
        const u32_max: u32 = 4_294_967_295;
        const u64_max: u64 = 18_446_744_073_709_551_615;
        const u128_max: u128 = 340_282_366_920_938_463_463_374_607_431_768_211_455;
        const custom_u65535_max: u65535 = undefined;

        const custom_i1_min: i1 = -1;
        const i8_min: i8 = -128;
        const i16_min: i16 = -32_768;
        const i32_min: i32 = -2_147_483_648;
        const i64_min: i64 = -9_223_372_036_854_775_808;
        const i128_min: i128 = -170_141_183_460_469_231_731_687_303_715_884_105_728;
        const custom_i65535_min: i65535 = undefined;

        _ = custom_u1_max;
        _ = u8_max;
        _ = u16_max;
        _ = u32_max;
        _ = u64_max;
        _ = u128_max;
        _ = custom_u65535_max;
        _ = custom_i1_min;
        _ = i8_min;
        _ = i16_min;
        _ = i32_min;
        _ = i64_min;
        _ = i128_min;
        _ = custom_i65535_min;
    }

    // tensor.scalar.float:
    {
        const f16_size: f16 = 2;
        const f32_size: f32 = f16_size * 2;
        const f64_size: f64 = f32_size * 2;
        const f80_size: f80 = f64_size * 2;
        const f128_size: f128 = f80_size;
        _ = f128_size;
    }

    // tensor.vector
    {
        const Vec1 = @Vector(1, f16);
        const Vec2: type = @Vector(2, f16);

        const a: Vec1 = .{0};
        const b = Vec2{ 1, 2 };
        const c: @Vector(3, f16) = .{ 3, 4, 5 };

        _ = a;
        _ = b;
        _ = c;
    }

    // constructor.error.literal:
    {
        const a = error.SkipZigTest;
        const b: error{SkipZigTest} = error.SkipZigTest;

        std.debug.print("{}\n{}\n", .{ a, b });
    }

    // constructor.error.set:
    {
        const a = error{};
        const b: type = error{
            OutOfMemory,
            FileNotFound,
            AccessDenied,
        };
        const c = b.OutOfMemory;
        const d: b = b.OutOfMemory;
        const e: b = error.OutOfMemory;
        const f: b = error{OutOfMemory}.OutOfMemory;

        std.debug.print("{}\n{}\n{}\n{}\n{}\n", .{ a, c, d, e, f });
    }

    // constructor.error.union:
    {
        const _a = error.SkipZigTest;
        const _b = error{SkipZigTest};

        const c: _b!u8 = _b.SkipZigTest;
        const d: _b!u8 = error.SkipZigTest;
        const _e = struct {
            inline fn f() !u8 {
                return _a;
            }
        };
        const g = _e.f();

        std.debug.print("{any}\n{any}\n{any}\n", .{ c, d, g });
    }

    // constructor.error.union.any:
    {
        const a: anyerror = error.SkipZigTest;
        const b: anyerror!u8 = a;

        std.debug.print("{any}\n", .{b});
    }

    // constructor.optional:
    {
        const a: ?u8 = 0;
        const b = null;
        const c: @TypeOf(null) = null;
        const d = a.?;
        const e: u8 = a.?;

        _ = b;
        _ = c;
        _ = d;
        _ = e;
    }

    // constructor.pointer:
    {
        const _a: u8 = undefined;
        const _b = [_]u8{ 0, 1 };

        const c = &_a;
        const d: *const u8 = &_a;
        const e: *const anyopaque = &_a;
        const f: [*]const u8 = &_b;
        const g = d.*;
        const h: u8 = d.*;

        _ = c;
        _ = e;
        _ = f;
        _ = g;
        _ = h;
    }

    // tensor.pointer.array:
    {
        const a = [_]u8{ 0, 1 };
        const b = [2]u8{ 2, 3 };
        const c = [_:0]u8{ 4, 5 };
        const d = [2:0]u8{ 6, 7 };
        const g: [2]u8 = .{ 8, 9 };
        const h: [2:0]u8 = .{ 10, 11 };

        const e = a.len;
        const f: usize = a.len;

        var _g: [2]u8 = undefined;
        _g = [_]u8{ 14, 15 };
        var _h: [2:0]u8 = undefined;
        _h = [_:0]u8{ 14, 15 };

        const k: [*]u8 = &_g;
        const l: [*]const u8 = &.{ 16, 17 };
        const m: [*:0]u8 = &_h;
        const n: [*:0]const u8 = &.{ 20, 21 };

        _ = b;
        _ = c;
        _ = d;
        _ = e;
        _ = f;
        _ = g;
        _ = h;
        _ = k;
        _ = l;
        _ = m;
        _ = n;
    }

    // tensor.pointer.array.string
    {
        const a = "\\\n\t\x41\u{1f525}\u{1F525}";
        const b: *const [5:0]u8 = "Hello";
        const c: *const [5]u8 = "Hello";

        const d =
            \\ First line
            \\ Second line
        ;
        const e: *const [24:0]u8 =
            \\ First line
            \\ Second line
        ;
        const f: *const [24]u8 =
            \\ First line
            \\ Second line
        ;

        _ = a;
        _ = b;
        _ = c;
        _ = d;
        _ = e;
        _ = f;
    }

    // tensor.pointer.array.slice:
    {
        const _a = [_]u8{ 0, 1, 2 };
        const _b = [_:0]u8{ 3, 4, 5 };

        const c = &_a;
        const d: []const u8 = &_a;
        const e: *const [3]u8 = &_a;
        const f = _a[0..];
        const g: []const u8 = _a[0..3];
        const h: *const [3]u8 = _a[0..3];

        const k = &_b;
        const l: [:0]const u8 = &_b;
        const m: *const [3:0]u8 = &_b;
        const n = _b[0.. :0];
        const o: [:0]const u8 = _b[0..3 :0];
        const p: *const [3:0]u8 = _b[0..3 :0];

        const q = h.len;
        const r: usize = h.len;

        const s = h.ptr;
        const t: [*]const u8 = h.ptr;
        const u = h.ptr;
        const v: [*:0]const u8 = p.ptr;

        _ = c;
        _ = d;
        _ = e;
        _ = f;
        _ = g;
        _ = k;
        _ = l;
        _ = m;
        _ = n;
        _ = o;
        _ = q;
        _ = r;
        _ = s;
        _ = t;
        _ = u;
        _ = v;
    }

    // tensor.pointer.array.slice.string
    {
        const a: []const u8 = "Hello";
        const b: [:0]const u8 = "Hello";

        _ = a;
        _ = b;
    }

    // composite.structure:
    {
        const a = struct {};
        const b = .{ .x = 0 };
        const c: type = packed struct {
            x: u4,
            y: u4,
        };
        const d = struct {
            const Self = @This();

            x: u8 = 0,

            var y: usize = 0;

            fn moveX(self: *Self, z: u8) void {
                defer {
                    y += 1;
                    Self.y += 1;
                }
                self.x += z;
                self.*.x += z;
            }
        };

        var e = d{};
        e.moveX(0);
        d.moveX(&e, 0);
        const f: d = d{};
        const g: d = .{ .x = 0 };
        const h = struct { x: u8 }{ .x = 0 };

        _ = a;
        _ = b;
        _ = c;
        _ = f;
        _ = g;
        _ = h;
    }

    // composite.structure.tuple:
    {
        const c = .{};
        const d: struct {} = .{};
        const a = struct { bool, u8 };
        const b: type = struct { bool, u8 };

        const e = .{0};
        const f: struct { comptime_int } = .{0};
        const g: a = .{ false, 0 };
        const h = a{ false, 0 };
        const k: struct { bool, u8 } = a{ false, 0 };
        const l = struct { bool, u8 }{ false, 0 };
        const m: struct { bool, u8 } = struct { bool, u8 }{ false, 0 };

        _ = b;
        _ = c;
        _ = d;
        _ = e;
        _ = f;
        _ = g;
        _ = h;
        _ = k;
        _ = l;
        _ = m;
    }

    // composite.union:
    {
        const a = union {};
        const b: type = union {};
        const c: type = packed union { x: u8 };
        const d: type = union { x: u8, y: u16 };

        const e: c = .{ .x = 0 };
        const f = c{ .x = 0 };
        const g: c = c{ .x = 0 };
        const h = union { x: u8 }{ .x = 0 };

        _ = a;
        _ = b;
        _ = d;
        _ = e;
        _ = f;
        _ = g;
        _ = h;
    }

    // composite.enumeration:
    {
        const a = enum {};
        const b: type = enum {};
        const c = enum(u8) { red, green, blue };

        const d = .red;
        const e: c = .red;
        const f = c.red;
        const g: c = c.red;
        const h: @EnumLiteral() = .green;

        _ = a;
        _ = b;
        _ = d;
        _ = e;
        _ = f;
        _ = g;
        _ = h;
    }

    // composite.union.enumeration:
    {
        const _a = enum { int, float };

        const b = union(_a) {
            int: i32,
            float: f32,
        };
        const c: type = union(enum) {
            int: i32,
            float: f32,
        };
        const d = union(enum(u8)) {
            int: i32,
            float: f32,
        };

        _ = b;
        _ = c;
        _ = d;
    }

    // composite.opaque
    {
        const a = opaque {};
        const b: type = opaque {};

        _ = a;
        _ = b;
    }

    // function:
    {
        const _a = struct {
            fn add(a: i32, b: i32) i32 {
                return a + b;
            }

            pub fn sub(a: i32, b: i32) i32 {
                return a - b;
            }
        };

        const b = _a.add;
        const c: fn (i32, i32) i32 = _a.sub;
        const d = b(1, 2);
        const e: i32 = c(1, 2);

        _ = d;
        _ = e;
    }

    // block:
    main_blk: {
        const a: void = blk: {
            break :blk;
        };
        const b = blk: {
            break :blk 0;
        };
        const c: comptime_int = blk: {
            break :blk 0;
        };
        const d = {
            break :main_blk;
        };
        const e: noreturn = {
            break :main_blk;
        };

        _ = a;
        _ = b;
        _ = c;
        _ = d;
        _ = e;
    }
}

test "comptime.variable" {
    comptime var a: u8 = 0;
    var b: u8 = comptime 0;

    a += 1;
    b += 1;

    const squares = blk: {
        comptime {
            var result: u8 = 0;
            result += 1;
            break :blk result;
        }
    };
    _ = squares;
}

// comptime.function
fn alloc(comptime T: type, n: usize) ![]T {
    const allocator = std.heap.page_allocator;
    return try allocator.alloc(T, n);
}

/// value.linksection
const linked_var: u8 linksection(".section") = 0;
fn linked_fn() linksection(".section") void {}

/// value.function.anytype
inline fn printValue(x: anytype) void {
    std.debug.print("{}\n", .{x});
}

/// value.function.noreturn
inline fn exit(status: u8) noreturn {
    std.process.exit(status);
}

/// qualifiers.accessibility
pub const public_var = 0;
const private_var = 0;

test "qualifiers.mutability" {
    var mutable: u8 = undefined;
    const immutable = mutable;

    mutable += 1;
    _ = immutable;
}

/// qualifiers.threadlocal:
threadlocal var thread_id_counter: u8 = 0;

test "qualifiers.pointer" {
    var data: u8 = undefined;
    var aligned_data: u32 align(@alignOf(u32)) = undefined;

    const const_ptr: *const u8 = &data;
    const volatile_ptr: *volatile u8 = &data;
    const zero_ptr: *allowzero u8 = @ptrFromInt(0);
    const aligned_ptr: *align(4) u32 = &aligned_data;
    const addressed_ptr: *addrspace(.generic) u8 = &data;

    _ = struct {
        fn copy(noalias dst: []u8, noalias src: []const u8) void {
            @memcpy(dst, src);
        }
    };

    _ = const_ptr;
    _ = volatile_ptr;
    _ = zero_ptr;
    _ = aligned_ptr;
    _ = addressed_ptr;
}
