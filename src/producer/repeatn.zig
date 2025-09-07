const std = @import("std");
const Iterator = @import("../iter.zig").Iterator;

/// Creates an iterator that yields nothing.
pub fn empty(Item: type) Iterator(RepeatN(Item)) {
    return .{ .iter = RepeatN(Item){ .item = undefined, .ntimes = 0 } };
}

/// Creates an iterator that yields an element exactly once.
pub fn once(Item: type, value: anytype) Iterator(RepeatN(Item)) {
    return .{ .iter = RepeatN(Item){ .item = value, .ntimes = 1 } };
}

/// Creates a new iterator that N times repeats a given value.
pub fn repeatN(Item: type, value: anytype, n: usize) Iterator(RepeatN(Item)) {
    return .{ .iter = RepeatN(Item){ .item = value, .ntimes = n } };
}

pub fn RepeatN(Item: type) type {
    return struct {
        item: Item,
        ntimes: usize,

        pub fn next(self: *@This()) ?Item {
            if (self.ntimes == 0) return null;

            self.ntimes -= 1;
            return self.item;
        }

        pub fn peek(self: *@This()) ?Item {
            if (self.ntimes == 0) return null;
            return self.item;
        }

        pub fn last(self: *@This()) ?Item {
            if (self.ntimes == 0) return null;

            self.ntimes = 0;
            return self.item;
        }

        pub fn nth(self: *@This(), n: usize) ?Item {
            if (n == 0) return self.next();

            if (n >= self.ntimes) {
                self.ntimes = 0;
                return null;
            }

            self.ntimes -= n;
            return self.next();
        }

        pub fn count(self: *@This()) usize {
            const c = self.ntimes;
            self.ntimes = 0;
            return c;
        }
    };
}

test "empty with filter" {
    var it = empty(u8);
    try std.testing.expectEqual(null, it.next());

    var it2 = empty(u8).filter(std.ascii.isAlphabetic);
    try std.testing.expectEqual(null, it2.next());

    it2 = empty(u8).filter(std.ascii.isAlphabetic);
    try std.testing.expectEqual(null, it2.next());
}

test "once with filter" {
    var it = once(u8, 'x');
    try std.testing.expectEqual('x', it.next().?);
    try std.testing.expectEqual(null, it.next());

    var it2 = once(u8, 'a').filter(std.ascii.isAlphabetic);
    try std.testing.expectEqual('a', it2.next().?);
    try std.testing.expectEqual(null, it2.next());

    it2 = once(u8, '1').filter(std.ascii.isAlphabetic);
    try std.testing.expectEqual(null, it2.next());
}

test "repeatN" {
    var it = repeatN(i32, 42, 4);
    try std.testing.expectEqual(42, it.next().?);
    try std.testing.expectEqual(42, it.next().?);
    try std.testing.expectEqual(42, it.next().?);
    try std.testing.expectEqual(42, it.next().?);
    try std.testing.expectEqual(null, it.next());

    const ptr: *const i32 = &42;
    var it2 = repeatN(*const i32, ptr, 1);
    try std.testing.expectEqual(ptr, it2.next().?);
    try std.testing.expectEqual(null, it2.next());

    var it3 = repeatN([]const u8, "abc_xyz", std.math.maxInt(usize));
    for (0..1000) |_| {
        try std.testing.expectEqualStrings("abc_xyz", it3.next().?);
    }
}

test "repeatN filter" {
    var it = repeatN(u8, 'a', 2).filter(std.ascii.isAlphabetic);
    try std.testing.expectEqual('a', it.next().?);
    try std.testing.expectEqual('a', it.next().?);
    try std.testing.expectEqual(null, it.next());

    it = repeatN(u8, '1', 2).filter(std.ascii.isAlphabetic);
    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(null, it.next());
}

test "repeat empty" {
    var it = empty(u8).iter;
    try std.testing.expectEqual(null, it.peek());
}

test "repeat once" {
    var it = once(u8, 'x').iter;

    try std.testing.expectEqual('x', it.peek().?);
    try std.testing.expectEqual('x', it.next().?);

    try std.testing.expectEqual(null, it.peek());
    try std.testing.expectEqual(null, it.next());
}

test "empty count" {
    var it = empty(u8);
    try std.testing.expectEqual(0, it.count());
}

test "once count" {
    var it = once(u8, 'x');
    try std.testing.expectEqual(1, it.count());

    it = once(u8, 'x');
    try std.testing.expectEqual('x', it.next().?);
    try std.testing.expectEqual(0, it.count());
    try std.testing.expectEqual(null, it.next());
}

test "repeatN count" {
    var it = repeatN(u8, 'a', 2);
    try std.testing.expectEqual('a', it.next().?);
    try std.testing.expectEqual(1, it.count());
    try std.testing.expectEqual(null, it.next());
}

test "repeatN nth" {
    {
        // nth = 0
        var it = repeatN(u8, 'a', 2).iter;
        try std.testing.expectEqual('a', it.nth(0).?);
        try std.testing.expectEqual('a', it.next().?);
        try std.testing.expectEqual(null, it.next());
    }

    {
        // nth = 1 (= last)
        var it = repeatN(u8, 'a', 2).iter;
        try std.testing.expectEqual('a', it.nth(1).?);
        try std.testing.expectEqual(null, it.next());
    }

    {
        // nth = 2 (= after last)
        var it = repeatN(u8, 'a', 2).iter;
        try std.testing.expectEqual(null, it.nth(2));
        try std.testing.expectEqual(null, it.next());
    }
}

test "repeatN last" {
    {
        var it = repeatN(u8, 'a', 2).iter;
        try std.testing.expectEqual('a', it.last().?);
        try std.testing.expectEqual(null, it.next());
    }

    {
        var it = repeatN(u8, 'a', 2).iter;
        try std.testing.expectEqual('a', it.next().?);
        try std.testing.expectEqual('a', it.last().?);
        try std.testing.expectEqual(null, it.next());
    }

    {
        var it = repeatN(u8, 'a', 2).iter;
        try std.testing.expectEqual(null, it.nth(2));
        try std.testing.expectEqual(null, it.last());
        try std.testing.expectEqual(null, it.next());
    }

    {
        var it = empty(u8).iter;
        try std.testing.expectEqual(null, it.last());
        try std.testing.expectEqual(null, it.next());
    }

    {
        var it = once(u8, 'a').iter;
        try std.testing.expectEqual('a', it.last().?);
        try std.testing.expectEqual(null, it.next());
    }

    {
        var it = once(u8, 'a').iter;
        try std.testing.expectEqual('a', it.next().?);
        try std.testing.expectEqual(null, it.last());
    }
}
