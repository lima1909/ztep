const std = @import("std");

// Hint:
// no reset or count from parent possible!!!
// because, the iter is null
//
pub fn Fuse(Iter: type, Item: type) type {
    return struct {
        iter: ?*Iter,

        pub fn next(self: *@This()) ?Item {
            if (self.iter) |iter| {
                return iter.next() orelse {
                    self.iter = null;
                    return null;
                };
            }

            return null;
        }
    };
}

test "fuse" {
    const fromFn = @import("producer/fromfn.zig").fromFn;

    var it = fromFn(i32, 1, struct {
        fn addOne(v: *i32) ?i32 {
            if (@rem(v.*, 3) == 0) return null;

            defer v.* += 1;
            return v.*;
        }
    }.addOne).fuse();

    try std.testing.expectEqual(1, it.next().?);
    try std.testing.expectEqual(2, it.next().?);
    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(null, it.next());
}
