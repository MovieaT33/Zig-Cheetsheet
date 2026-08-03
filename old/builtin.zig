pub fn main() void {
    // 1. Builtins functions
    // 2. For ex. builtin.os.tag
    // 3. @TypeOf()

    // region types:as:local
    {
        var int = @as(u8, 0);
        const float = @as(f16, 3.14);

        int = 0;
        _ = float;
    }
    // endregion
}
