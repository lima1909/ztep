const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

pub fn Peekable(Iter: type, Item: type) type {
    return struct {
        iter: *Iter,
        parent: *Iterator(Iter),
        peeked: ??Item = null,

        pub fn init(iter: *Iter) @This() {
            return .{
                .iter = iter,
                .parent = @fieldParentPtr("iter", iter),
            };
        }

        pub fn next(self: *@This()) ?Item {
            if (self.peeked == null)
                return self.iter.next();

            if (self.peeked.?) |peeked| {
                self.peeked = null;
                return peeked;
            }

            return null;
        }

        pub fn peek(self: *@This()) ?Item {
            if (self.peeked == null) {
                self.peeked = self.iter.next();
                return self.peeked orelse null;
            }

            return self.peeked.?;
        }

        pub fn count(self: *@This()) usize {
            if (self.peeked == null)
                return self.parent.count();

            if (self.peeked.? == null)
                return 0;

            return self.parent.count() + 1;
        }
    };
}

test "peekable" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB", ' ');
    var it = Peekable(@TypeOf(tokensIt), []const u8).init(&tokensIt);

    try std.testing.expectEqual(2, it.count());
    it.iter.reset();

    try std.testing.expectEqualStrings("a", it.peek().?);
    try std.testing.expectEqualStrings("a", it.next().?);

    try std.testing.expectEqualStrings("BB", it.peek().?);
    try std.testing.expectEqualStrings("BB", it.peek().?);
    try std.testing.expectEqualStrings("BB", it.next().?);

    try std.testing.expectEqual(null, it.peek());
    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(0, it.count());
}
