const std = @import("std");

pub fn Map(Iter: type, Item: type, To: type) type {
    return struct {
        it: *Iter,
        mapFn: *const fn (Item) To,

        pub fn next(self: *@This()) ?To {
            const item = self.it.next() orelse return null;
            return self.mapFn(item);
        }
    };
}

test "map" {
    var tokensIt = std.mem.tokenizeScalar(u8, "x BB ccc", ' ');
    var it = Map(@TypeOf(tokensIt), []const u8, u8){
        .it = &tokensIt,
        .mapFn = struct {
            fn firstChar(in: []const u8) u8 {
                return in[0];
            }
        }.firstChar,
    };

    try std.testing.expectEqual('x', it.next().?);
    try std.testing.expectEqual('B', it.next().?);
    try std.testing.expectEqual('c', it.next().?);
    try std.testing.expectEqual(null, it.next());
}

pub fn Filter(Iter: type, Item: type) type {
    return struct {
        it: *Iter,
        filterFn: *const fn (Item) bool,

        pub fn next(self: *@This()) ?Item {
            while (self.it.next()) |item| {
                if (self.filterFn(item)) {
                    return item;
                }
            }

            return null;
        }
    };
}

test "filter" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Filter(@TypeOf(tokensIt), []const u8){
        .it = &tokensIt,
        .filterFn = struct {
            fn firstCharUpper(in: []const u8) bool {
                return std.ascii.isUpper(in[0]);
            }
        }.firstCharUpper,
    };

    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

pub fn Enumerate(Iter: type, Item: type) type {
    return struct {
        it: *Iter,
        index: usize = 0,

        pub fn next(self: *@This()) ?struct { usize, Item } {
            const item = self.it.next() orelse return null;
            defer self.index += 1;
            return .{ self.index, item };
        }
    };
}

test "enumerate" {
    var tokensIt = std.mem.tokenizeScalar(u8, "x BB ccc", ' ');
    var it = Enumerate(@TypeOf(tokensIt), []const u8){ .it = &tokensIt };

    try std.testing.expectEqualDeep(.{ 0, "x" }, it.next().?);
    try std.testing.expectEqualDeep(.{ 1, "BB" }, it.next().?);
    try std.testing.expectEqualDeep(.{ 2, "ccc" }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}

pub fn Inspect(Iter: type, Item: type) type {
    return struct {
        it: *Iter,
        inspectFn: *const fn (Item) Item,

        pub fn next(self: *@This()) ?Item {
            const item = self.it.next() orelse return null;
            return self.inspectFn(item);
        }
    };
}

test "inspect" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Inspect(@TypeOf(tokensIt), []const u8){
        .it = &tokensIt,
        .inspectFn = struct {
            fn inspect(in: []const u8) []const u8 {
                return in;
            }
        }.inspect,
    };

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

pub fn Skip(Iter: type, Item: type) type {
    return struct {
        it: *Iter,
        n: usize,

        pub fn next(self: *@This()) ?Item {
            for (0..self.n) |_| {
                _ = self.it.next() orelse return null;
            }
            // disable skip
            self.n = 0;

            return self.it.next();
        }
    };
}

test "skip" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Skip(@TypeOf(tokensIt), []const u8){
        .it = &tokensIt,
        .n = 2,
    };

    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "skip on the end" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Skip(@TypeOf(tokensIt), []const u8){
        .it = &tokensIt,
        .n = 4,
    };

    try std.testing.expectEqual(null, it.next());
}

test "skip after the end" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Skip(@TypeOf(tokensIt), []const u8){
        .it = &tokensIt,
        .n = 5,
    };

    try std.testing.expectEqual(null, it.next());
}

test "skip nothing" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Skip(@TypeOf(tokensIt), []const u8){
        .it = &tokensIt,
        .n = 0,
    };

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

pub fn Take(Iter: type, Item: type) type {
    return struct {
        it: *Iter,
        n: usize = 0,

        pub fn next(self: *@This()) ?Item {
            if (self.n != 0) {
                self.n -= 1;
                return self.it.next();
            }

            return null;
        }
    };
}

test "take" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Take(@TypeOf(tokensIt), []const u8){
        .it = &tokensIt,
        .n = 2,
    };

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "take after the end" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = Take(@TypeOf(tokensIt), []const u8){
        .it = &tokensIt,
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
        .it = &tokensIt,
        .n = 0,
    };

    try std.testing.expectEqual(null, it.next());
}
