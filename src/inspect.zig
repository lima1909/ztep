const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

pub fn Inspect(Iter: type, Item: type) type {
    return struct {
        iter: *Iter,
        parent: *Iterator(Iter),
        inspectFn: *const fn (Item) Item,

        pub fn init(iter: *Iter, inspectFn: *const fn (Item) Item) @This() {
            return .{
                .iter = iter,
                .inspectFn = inspectFn,
                .parent = @fieldParentPtr("iter", iter),
            };
        }

        pub fn next(self: *@This()) ?Item {
            return self.inspectFn(self.iter.next() orelse return null);
        }

        pub fn reset(self: *@This()) void {
            return self.parent.reset();
        }

        pub fn count(self: *@This()) usize {
            return self.parent.count();
        }
    };
}

test "inspect" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Inspect(@TypeOf(tokensIt), []const u8).init(
        &tokensIt,
        struct {
            fn inspect(in: []const u8) []const u8 {
                return in;
            }
        }.inspect,
    );

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqual(null, it.next());
}
