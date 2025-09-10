const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

pub fn Map(Iter: type, Item: type, To: type) type {
    return struct {
        iter: *Iter,
        parent: *Iterator(Iter),
        mapFn: *const fn (Item) To,

        pub fn init(iter: *Iter, mapFn: *const fn (Item) To) @This() {
            return .{
                .iter = iter,
                .mapFn = mapFn,
                .parent = @fieldParentPtr("iter", iter),
            };
        }

        pub fn next(self: *@This()) ?To {
            return self.mapFn(self.iter.next() orelse return null);
        }

        pub fn reset(self: *@This()) void {
            return self.parent.reset();
        }

        pub fn count(self: *@This()) usize {
            return self.parent.count();
        }
    };
}

test "map" {
    var tokensIt = std.mem.tokenizeScalar(u8, "x BB ccc", ' ');
    var it = Map(@TypeOf(tokensIt), []const u8, u8).init(
        &tokensIt,
        struct {
            fn firstChar(in: []const u8) u8 {
                return in[0];
            }
        }.firstChar,
    );

    try std.testing.expectEqual(3, it.count());
    tokensIt.reset();

    try std.testing.expectEqual('x', it.next().?);
    try std.testing.expectEqual('B', it.next().?);
    try std.testing.expectEqual('c', it.next().?);
    try std.testing.expectEqual(null, it.next());

    try std.testing.expectEqual(0, it.count());
}
