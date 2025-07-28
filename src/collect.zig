const std = @import("std");

pub fn Collector(Iter: type, Item: type) type {
    return struct {
        it: *Iter,

        pub fn collect(self: *@This(), buffer: []Item) ?usize {
            const len = buffer.len;
            var read: usize = 0;

            for (0..len) |i| {
                const item = self.it.next() orelse break;
                buffer[i] = item;
                read += 1;
            }

            if (read > 0) return read;
            return null;
        }
    };
}

test "collect" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var collector = Collector(@TypeOf(tokensIt), []const u8){ .it = &tokensIt };

    const result: []const []const []const u8 = &.{
        &.{ "a", "BB", "ccc" },
        &.{"DDD"},
    };

    var i: usize = 0;
    var buffer: [3][]const u8 = undefined;
    while (collector.collect(&buffer)) |n| {
        try std.testing.expectEqualDeep(result[i], buffer[0..n]);
        i += 1;
    }
}

test "collect empty" {
    var tokensIt = std.mem.tokenizeScalar(u8, "", ' ');
    var collector = Collector(@TypeOf(tokensIt), []const u8){ .it = &tokensIt };

    var buffer: [3][]const u8 = undefined;
    try std.testing.expectEqual(null, collector.collect(&buffer));
}
