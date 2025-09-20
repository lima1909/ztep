const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

pub fn Take(Iter: type, Item: type) type {
    return struct {
        iter: *Iter,
        n: usize = 0,

        pub fn next(self: *@This()) ?Item {
            if (self.n == 0)
                return null;

            self.n -= 1;
            return self.iter.next();
        }

        pub fn nth(self: *@This(), n: usize) ?Item {
            var parent: *Iterator(Iter) = @fieldParentPtr("iter", self.iter);

            if (self.n > n) {
                self.n -= n + 1;
                return parent.nth(n);
            }

            if (self.n > 0) {
                _ = parent.nth(self.n - 1);
                self.n = 0;
            }

            return null;
        }
    };
}

test "take" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Take(@TypeOf(tokensIt), []const u8){ .iter = &tokensIt, .n = 2 };

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "take after the end" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Take(@TypeOf(tokensIt), []const u8){ .iter = &tokensIt, .n = 5 };

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "take nothing" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Take(@TypeOf(tokensIt), []const u8){ .iter = &tokensIt, .n = 0 };

    try std.testing.expectEqual(null, it.next());
}

test "skip nth" {
    {
        var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
        var it = Take(@TypeOf(tokensIt), []const u8){ .iter = &tokensIt, .n = 3 };

        try std.testing.expectEqualStrings("BB", it.nth(1).?);
        try std.testing.expectEqualStrings("ccc", it.next().?);
        try std.testing.expectEqual(null, it.next());
    }

    {
        var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
        var it = Take(@TypeOf(tokensIt), []const u8){ .iter = &tokensIt, .n = 2 };

        try std.testing.expectEqualStrings("BB", it.nth(1).?);
        try std.testing.expectEqual(null, it.next());
    }

    {
        var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
        var it = Take(@TypeOf(tokensIt), []const u8){ .iter = &tokensIt, .n = 1 };

        try std.testing.expectEqual(null, it.nth(2));
        try std.testing.expectEqual(null, it.next());
    }

    {
        var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
        var it = Take(@TypeOf(tokensIt), []const u8){ .iter = &tokensIt, .n = 0 };

        try std.testing.expectEqual(null, it.nth(2));
        try std.testing.expectEqual(null, it.next());
    }
}
