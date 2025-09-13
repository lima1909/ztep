const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

pub fn Result(Iter: type, Item: type) type {
    return struct {
        iter: *Iter,
        err: ?anyerror = null,
        err_item: ?Item = null,

        pub fn next(self: *@This()) ?Item {
            return self.iter.next();
        }

        pub fn hasError(self: *const @This()) bool {
            return self.err != null;
        }

        pub fn extend(self: @This()) Iterator(@This()) {
            return Iterator(@This()){ .iter = self };
        }
    };
}

test "result" {
    var tokensIt = std.mem.tokenizeScalar(u8, "x BB ccc", ' ');
    var it = Result(@TypeOf(tokensIt), []const u8){
        .iter = &tokensIt,
    };

    try std.testing.expect(!it.hasError());

    try std.testing.expectEqualStrings("x", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "result extend" {
    var tokensIt = std.mem.tokenizeScalar(u8, "x BB ccc", ' ');
    var it = Result(@TypeOf(tokensIt), []const u8){
        .iter = &tokensIt,
    };

    try std.testing.expectEqual(3, it.extend().count());
}
