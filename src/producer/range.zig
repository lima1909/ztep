const std = @import("std");
const Iterator = @import("../iter.zig").Iterator;

/// Create a new Iterator for the given range, from start to exclude end.
pub fn range(Item: type, start: Item, end: Item) Iterator(Range(Item)) {
    return .{ .iter = Range(Item){
        .start = start,
        .end = end,
    } };
}

/// Create a new Iterator for the given range, like range, but the end is inclusive.
pub fn rangeIncl(Item: type, start: Item, end: Item) Iterator(Range(Item)) {
    return .{ .iter = Range(Item){
        .start = start,
        .end = end,
        .inclusive = true,
    } };
}

pub fn Range(Item: type) type {
    return struct {
        start: Item,
        end: Item,
        inclusive: bool = false,

        inline fn isOnTheEnd(self: *const @This()) bool {
            return (self.start > self.end or (!self.inclusive and self.start == self.end));
        }

        /// next from the front-side
        pub fn next(self: *@This()) ?Item {
            if (self.isOnTheEnd()) return null;

            const start = self.start;
            self.start += 1;
            return start;
        }

        /// next from the end-side
        pub fn nextBack(self: *@This()) ?Item {
            if (self.isOnTheEnd()) return null;

            self.end -= 1;
            return self.end;
        }

        pub fn nth(self: *@This(), n: usize) ?Item {
            switch (Item) {
                u8, u16, u32, u64, usize => {
                    if (n == 0) return self.next();

                    if (self.isOnTheEnd()) {
                        self.start = self.end;
                        return null;
                    }

                    self.start += @intCast(n);
                    return self.next();
                },
                else => {
                    var i: usize = 0;
                    while (self.next()) |item| : (i += 1) {
                        if (i == n) {
                            return item;
                        }
                    }
                    return null;
                },
            }
        }

        pub fn count(self: *@This()) usize {
            switch (Item) {
                u8, u16, u32, u64, usize => {
                    if (self.isOnTheEnd()) return 0;

                    const c = self.end - self.start;
                    self.start = self.end;
                    return c;
                },
                else => {
                    var counter: usize = 0;
                    while (self.next() != null) : (counter += 1) {}
                    return counter;
                },
            }
        }
    };
}

test "range u8" {
    var buffer: [4]u8 = undefined;
    const n = try range(u8, 'a', 'd').tryCollect(&buffer);
    try std.testing.expectEqualStrings("abc", buffer[0..n]);
}

test "rangeIncl char" {
    var buffer: [4]u8 = undefined;
    const n = try rangeIncl(u8, 'a', 'd').tryCollect(&buffer);
    try std.testing.expectEqualStrings("abcd", buffer[0..n]);
}

test "rangeIncl i32" {
    var buffer: [10]i32 = undefined;
    const n = try rangeIncl(i32, 1, 6).tryCollect(&buffer);
    try std.testing.expectEqualDeep(&[_]i32{ 1, 2, 3, 4, 5, 6 }, buffer[0..n]);
}

test "range i32" {
    var buffer: [10]i32 = undefined;
    const n = try range(i32, 1, 6).tryCollect(&buffer);
    try std.testing.expectEqualDeep(&[_]i32{ 1, 2, 3, 4, 5 }, buffer[0..n]);
}

test "range i32 next" {
    var it = range(i32, 1, 5).iter;

    try std.testing.expectEqualDeep(1, it.next());
    try std.testing.expectEqualDeep(2, it.next());
    try std.testing.expectEqualDeep(3, it.next());
    try std.testing.expectEqualDeep(4, it.next());
    try std.testing.expectEqualDeep(null, it.next());
    try std.testing.expectEqualDeep(null, it.nextBack());
}

test "range i32 back" {
    var it = range(i32, 1, 5).iter;

    try std.testing.expectEqualDeep(4, it.nextBack());
    try std.testing.expectEqualDeep(3, it.nextBack());
    try std.testing.expectEqualDeep(2, it.nextBack());
    try std.testing.expectEqualDeep(1, it.nextBack());
    try std.testing.expectEqualDeep(null, it.next());
    try std.testing.expectEqualDeep(null, it.nextBack());
}

test "range i32 next and back" {
    var it = range(i32, 1, 5).iter;

    try std.testing.expectEqualDeep(4, it.nextBack());
    try std.testing.expectEqualDeep(1, it.next());
    try std.testing.expectEqualDeep(3, it.nextBack());
    try std.testing.expectEqualDeep(2, it.next());
    try std.testing.expectEqualDeep(null, it.next());
    try std.testing.expectEqualDeep(null, it.nextBack());
}

test "range i32 filter " {
    var it = range(i32, 1, 10).filter(struct {
        fn isEven(i: i32) bool {
            return @mod(i, 2) == 0;
        }
    }.isEven);

    try std.testing.expectEqualDeep(2, it.next());
    try std.testing.expectEqualDeep(4, it.next());
    try std.testing.expectEqualDeep(6, it.next());
    try std.testing.expectEqualDeep(8, it.next());
}

test "range i32 start > end" {
    var it = range(i32, 5, 1).iter;

    try std.testing.expectEqualDeep(null, it.next());
    try std.testing.expectEqualDeep(null, it.nextBack());
}

test "range i32 peek" {
    var it = range(i32, 1, 3).peekable();

    try std.testing.expectEqualDeep(1, it.peek());
    try std.testing.expectEqualDeep(1, it.next());

    try std.testing.expectEqualDeep(2, it.peek());
    try std.testing.expectEqualDeep(2, it.next());

    try std.testing.expectEqual(null, it.peek());
    try std.testing.expectEqual(null, it.next());
}

test "range i32 count" {
    var it = range(i32, -1, 5);

    try std.testing.expectEqual(-1, it.next().?);
    try std.testing.expectEqual(5, it.count());
    try std.testing.expectEqual(null, it.next());
}

test "range u8 count" {
    var it = range(u8, 1, 5);

    try std.testing.expectEqual(1, it.next().?);
    try std.testing.expectEqual(3, it.count());
    try std.testing.expectEqual(null, it.next());
}

test "range u8 count start > end" {
    var it = range(u8, 5, 1);

    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(0, it.count());
}

test "range char count" {
    var it = range(u8, 'b', 'd');

    try std.testing.expectEqual('b', it.next().?);
    try std.testing.expectEqual(1, it.count());
    try std.testing.expectEqual(null, it.next());
}

test "range char nth" {
    {
        // nth = 0
        var it = range(u8, 'a', 'c').iter;
        try std.testing.expectEqual('a', it.nth(0).?);
        try std.testing.expectEqual('b', it.next().?);
        try std.testing.expectEqual(null, it.next());
    }

    {
        // nth = 1 (= last)
        var it = range(u8, 'a', 'c').iter;
        try std.testing.expectEqual('b', it.nth(1).?);
        try std.testing.expectEqual(null, it.next());
    }

    {
        // nth = 2 (= after last)
        var it = range(u8, 'a', 'c').iter;
        try std.testing.expectEqual(null, it.nth(2));
        try std.testing.expectEqual(null, it.next());
    }
}

test "range i32 nth" {
    {
        // nth = 0
        var it = range(i32, -2, 0).iter;
        try std.testing.expectEqual(-2, it.nth(0).?);
        try std.testing.expectEqual(-1, it.next().?);
        try std.testing.expectEqual(null, it.next());
    }

    {
        // nth = 1 (= last)
        var it = range(i32, -2, 0).iter;
        try std.testing.expectEqual(-1, it.nth(1).?);
        try std.testing.expectEqual(null, it.next());
    }

    {
        // nth = 2 (= after last)
        var it = range(i32, -2, 0).iter;
        try std.testing.expectEqual(null, it.nth(2));
        try std.testing.expectEqual(null, it.next());
    }
}

test "rangeIncl char nth" {
    {
        // nth = 0
        var it = rangeIncl(u8, 'a', 'b').iter;
        try std.testing.expectEqual('a', it.nth(0).?);
        try std.testing.expectEqual('b', it.next().?);
        try std.testing.expectEqual(null, it.next());
    }

    {
        // nth = 1 (= last)
        var it = rangeIncl(u8, 'a', 'b').iter;
        try std.testing.expectEqual('b', it.nth(1).?);
        try std.testing.expectEqual(null, it.next());
    }

    {
        // nth = 2 (= after last)
        var it = rangeIncl(u8, 'a', 'b').iter;
        try std.testing.expectEqual(null, it.nth(2));
        try std.testing.expectEqual(null, it.next());
    }
}
