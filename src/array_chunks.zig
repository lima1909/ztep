const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

pub fn ArrayChunks(Iter: type, Item: type, comptime n: usize) type {
    return struct {
        iter: *Iter,
        remainder: ?[n]?Item = null,
        parent: *Iterator(Iter),

        pub fn init(iter: *Iter) @This() {
            return .{
                .iter = iter,
                .parent = @fieldParentPtr("iter", iter),
            };
        }

        pub fn next(self: *@This()) ?[n]Item {
            var items: [n]Item = undefined;

            inline for (0..n) |i| {
                if (self.iter.next()) |item| {
                    items[i] = item;
                } else if (i == 0) {
                    // no items anymore, no reminder
                    return null;
                } else {
                    self.remainder = .{null} ** n;
                    for (0..i) |x| {
                        self.remainder.?[x] = items[x];
                    }
                    return null;
                }
            }

            return items;
        }

        pub fn reset(self: *@This()) void {
            return self.parent.reset();
        }

        pub fn count(self: *@This()) usize {
            return @divTrunc(self.parent.count(), n);
        }
    };
}

test "arrayChunks 1" {
    var tokensIt = std.mem.tokenizeScalar(u8, "x BB ccc", ' ');
    var it = ArrayChunks(@TypeOf(tokensIt), []const u8, 1).init(&tokensIt);

    try std.testing.expectEqualDeep([_][]const u8{"x"}, it.next().?);
    try std.testing.expectEqualDeep([_][]const u8{"BB"}, it.next().?);
    try std.testing.expectEqualDeep([_][]const u8{"ccc"}, it.next().?);
    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(null, it.remainder);

    it.reset();
    try std.testing.expectEqual(3, it.count());
}

test "arrayChunks 2" {
    var tokensIt = std.mem.tokenizeScalar(u8, "x BB ccc", ' ');
    var it = ArrayChunks(@TypeOf(tokensIt), []const u8, 2).init(&tokensIt);

    try std.testing.expectEqualDeep([_][]const u8{ "x", "BB" }, it.next().?);
    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqualDeep([_]?[]const u8{ "ccc", null }, it.remainder);

    it.reset();
    try std.testing.expectEqual(1, it.count());
}

test "arrayChunks 3" {
    {
        var tokensIt = std.mem.tokenizeScalar(u8, "x BB ccc", ' ');
        var it = ArrayChunks(@TypeOf(tokensIt), []const u8, 3).init(&tokensIt);

        try std.testing.expectEqualDeep([_][]const u8{ "x", "BB", "ccc" }, it.next().?);
        try std.testing.expectEqual(null, it.next());
        try std.testing.expectEqual(null, it.remainder);
    }

    {
        var tokensIt = std.mem.tokenizeScalar(u8, "x BB ccc", ' ');
        var it = ArrayChunks(@TypeOf(tokensIt), []const u8, 3).init(&tokensIt);

        try std.testing.expectEqual(1, it.count());
    }
}

test "arrayChunks 4" {
    {
        var tokensIt = std.mem.tokenizeScalar(u8, "x BB ccc", ' ');
        var it = ArrayChunks(@TypeOf(tokensIt), []const u8, 4).init(&tokensIt);

        try std.testing.expectEqual(null, it.next());
        try std.testing.expectEqualDeep([_]?[]const u8{ "x", "BB", "ccc", null }, it.remainder);
    }

    {
        var tokensIt = std.mem.tokenizeScalar(u8, "x BB ccc", ' ');
        var it = ArrayChunks(@TypeOf(tokensIt), []const u8, 4).init(&tokensIt);

        try std.testing.expectEqual(0, it.count());
    }
}
