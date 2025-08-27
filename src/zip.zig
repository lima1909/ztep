const std = @import("std");

pub fn Zip(Iter1: type, Iter2: type, Item: type) type {
    return struct {
        first: *Iter1,
        second: Iter2,

        pub fn next(self: *@This()) ?struct { Item, Item } {
            return .{
                self.first.next() orelse return null,
                self.second.next() orelse return null,
            };
        }
    };
}

test "zip" {
    var firstIt = std.mem.tokenizeScalar(u8, "a BB", ' ');
    var it = Zip(@TypeOf(firstIt), std.mem.TokenIterator(u8, .scalar), []const u8){
        .first = &firstIt,
        .second = std.mem.tokenizeScalar(u8, "ccc DDD", ' '),
    };

    try std.testing.expectEqualDeep(.{ "a", "ccc" }, it.next().?);
    try std.testing.expectEqualDeep(.{ "BB", "DDD" }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}
