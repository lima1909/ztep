const std = @import("std");

pub fn Take(Iter: type, Item: type) type {
    return struct {
        iter: *Iter,
        n: usize = 0,

        pub fn next(self: *@This()) ?Item {
            if (self.n != 0) {
                self.n -= 1;
                return self.iter.next();
            }

            return null;
        }
    };
}

test "take" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Take(@TypeOf(tokensIt), []const u8){
        .iter = &tokensIt,
        .n = 2,
    };

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "take after the end" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Take(@TypeOf(tokensIt), []const u8){
        .iter = &tokensIt,
        .n = 5,
    };

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "take nothing" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Take(@TypeOf(tokensIt), []const u8){
        .iter = &tokensIt,
        .n = 0,
    };

    try std.testing.expectEqual(null, it.next());
}
