// region test:contents
// [1] test:named:string
// [2] test:named:identifier
// [3] test:anonymous
// [4] test:failure
// [5] test:skip
// [6] test:leak_detection
// endregion

const std = @import("std");

inline fn addOne(num: i32) i32 {
    return num + 1;
}

// region test:named:string
test "expect addOne adds one to 5" {
    try std.testing.expect(addOne(5) == 6);
    try std.testing.expectEqual(@as(i32, 6), addOne(5));
}
// endregion

// region test:named:identifier
test addOne {
    try std.testing.expectEqual(@as(i32, 6), addOne(5));
}
// endregion

// region test:anonymous
test {
    const res = addOne(0);
    try std.testing.expect(res == 1);
}
// endregion

// region test:failure
test "expect this to fail" {
    if (false)
        try std.testing.expect(false);
}
// endregion

// region test:skip
test "this will be skipped" {
    return error.SkipZigTest; // magic value
}
// endregion

// region test:leak_detection
test "detect leak" {
    const allocator = std.testing.allocator;

    var list: std.ArrayList(u21) = .empty;
    defer list.deinit(allocator);

    try list.append(allocator, '☔');
    try std.testing.expectEqual(@as(usize, 1), list.items.len);
}
// endregion
