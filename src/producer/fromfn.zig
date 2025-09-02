const std = @import("std");
const Iterator = @import("../iter.zig").Iterator;

/// Creates an custom iterator with the initialized (start) value and the provided (next) function.
pub fn fromFn(Item: type, init: Item, nextFn: *const fn (*Item) ?Item) Iterator(FromFn(Item)) {
    return .{ .iter = FromFn(Item){
        .value = init,
        .callback = nextFn,
    } };
}

pub fn FromFn(Item: type) type {
    return struct {
        value: Item,
        callback: *const fn (*Item) ?Item,

        pub fn next(self: *@This()) ?Item {
            return self.callback(&self.value);
        }
    };
}

test "fromFn, simple counter until 5" {
    var it = fromFn(i32, 0, struct {
        fn next(v: *i32) ?i32 {
            v.* += 1;
            if (v.* <= 5)
                return v.*
            else
                return null;
        }
    }.next)
        .filter(struct {
        fn isEven(i: i32) bool {
            return @mod(i, 2) == 0;
        }
    }.isEven);

    try std.testing.expectEqual(2, it.next().?);
    try std.testing.expectEqual(4, it.next().?);
    try std.testing.expectEqual(null, it.next());
}
