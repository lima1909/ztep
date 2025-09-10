const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

pub fn Filter(Iter: type, Item: type) type {
    return struct {
        iter: *Iter,
        parent: *Iterator(Iter),
        filterFn: *const fn (Item) bool,

        pub fn init(iter: *Iter, filterFn: *const fn (Item) bool) @This() {
            return .{
                .iter = iter,
                .filterFn = filterFn,
                .parent = @fieldParentPtr("iter", iter),
            };
        }

        pub fn next(self: *@This()) ?Item {
            while (self.iter.next()) |item| {
                if (self.filterFn(item)) {
                    return item;
                }
            }

            return null;
        }

        pub fn reset(self: *@This()) void {
            return self.parent.reset();
        }
    };
}

test "filter" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Filter(@TypeOf(tokensIt), []const u8).init(
        &tokensIt,
        struct {
            fn firstCharUpper(in: []const u8) bool {
                return std.ascii.isUpper(in[0]);
            }
        }.firstCharUpper,
    );

    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqual(null, it.next());
}
