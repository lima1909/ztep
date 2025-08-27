const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

pub fn Chain(Iter1: type, Iter2: type, Item: type) type {
    return struct {
        first: *Iter1,
        second: Iter2,

        pub fn next(self: *@This()) ?Item {
            return self.first.next() orelse self.second.next();
        }

        pub fn count(self: *@This()) usize {
            var pFirst: *Iterator(Iter1) = @fieldParentPtr("iter", self.first);
            var pSecond: *Iterator(Iter2) = @fieldParentPtr("iter", &self.second);
            return pFirst.count() + pSecond.count();
        }
    };
}

test "chain" {
    var firstIt = std.mem.tokenizeScalar(u8, "a BB", ' ');
    const secondIt = Iterator(std.mem.TokenIterator(u8, .scalar)){ .iter = std.mem.tokenizeScalar(u8, "ccc DDD", ' ') };
    var it = Chain(@TypeOf(firstIt), @TypeOf(secondIt), []const u8){
        .first = &firstIt,
        .second = secondIt,
    };

    try std.testing.expectEqual(4, it.count());
    firstIt.reset();
    it.second.iter.reset();

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(0, it.count());
}
