const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

pub fn Inspect(Iter: type, Item: type) type {
    return struct {
        iter: *Iter,
        inspectFn: *const fn (Item) Item,

        pub fn next(self: *@This()) ?Item {
            return self.inspectFn(self.iter.next() orelse return null);
        }

        pub fn reset(self: *@This()) void {
            var parent: *Iterator(Iter) = @fieldParentPtr("iter", self.iter);
            parent.reset();
        }

        pub fn count(self: *@This()) usize {
            var parent: *Iterator(Iter) = @fieldParentPtr("iter", self.iter);
            return parent.count();
        }
    };
}

test "inspect" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Inspect(@TypeOf(tokensIt), []const u8){
        .iter = &tokensIt,
        .inspectFn = struct {
            fn inspect(in: []const u8) []const u8 {
                return in;
            }
        }.inspect,
    };

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqual(null, it.next());
}
