const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

pub fn Skip(Iter: type, Item: type) type {
    return struct {
        iter: *Iter,
        parent: *Iterator(Iter),
        n: usize,

        pub fn init(iter: *Iter, n: usize) @This() {
            return .{
                .iter = iter,
                .n = n,
                .parent = @fieldParentPtr("iter", iter),
            };
        }

        pub fn next(self: *@This()) ?Item {
            if (self.n == 0)
                return self.iter.next();

            const n = self.n;
            // disable skip
            self.n = 0;

            return self.parent.nth(n);
        }

        pub fn nth(self: *@This(), n: usize) ?Item {
            if (self.n == 0)
                return self.parent.nth(n);

            return self.parent.nth(self.n + n);
        }

        pub fn count(self: *@This()) usize {
            if (self.n > 0 and self.parent.nth(self.n - 1) == null) {
                return 0;
            }

            return self.parent.count();
        }
    };
}

test "skip" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Skip(@TypeOf(tokensIt), []const u8).init(&tokensIt, 2);

    try std.testing.expectEqual(2, it.count());
    it.iter.reset();

    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "skip on the end" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Skip(@TypeOf(tokensIt), []const u8).init(&tokensIt, 4);

    try std.testing.expectEqual(null, it.next());
}

test "skip after the end" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Skip(@TypeOf(tokensIt), []const u8).init(&tokensIt, 5);

    try std.testing.expectEqual(null, it.next());
}

test "skip nothing" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Skip(@TypeOf(tokensIt), []const u8).init(&tokensIt, 0);

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "skip nth" {
    {
        var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
        var it = Skip(@TypeOf(tokensIt), []const u8).init(&tokensIt, 2);

        try std.testing.expectEqualStrings("DDD", it.nth(1).?);
        try std.testing.expectEqual(null, it.next());
    }

    {
        var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
        var it = Skip(@TypeOf(tokensIt), []const u8).init(&tokensIt, 0);

        try std.testing.expectEqualStrings("ccc", it.nth(2).?);
        try std.testing.expectEqualStrings("DDD", it.next().?);
        try std.testing.expectEqual(null, it.next());
    }
}
