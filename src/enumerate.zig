const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

pub fn Enumerate(Iter: type, Item: type) type {
    return struct {
        iter: *Iter,
        parent: *Iterator(Iter),
        index: usize = 0,

        pub fn init(iter: *Iter) @This() {
            return .{
                .iter = iter,
                .parent = @fieldParentPtr("iter", iter),
            };
        }

        pub fn next(self: *@This()) ?struct { usize, Item } {
            const item = self.iter.next() orelse return null;
            defer self.index += 1;
            return .{ self.index, item };
        }

        pub fn reset(self: *@This()) void {
            self.index = 0;
            return self.parent.reset();
        }

        pub fn count(self: *@This()) usize {
            return self.parent.count();
        }
    };
}

test "enumerate" {
    var tokensIt = std.mem.tokenizeScalar(u8, "x BB ccc", ' ');
    var it = Enumerate(@TypeOf(tokensIt), []const u8).init(&tokensIt);

    try std.testing.expectEqualDeep(.{ 0, "x" }, it.next().?);
    try std.testing.expectEqualDeep(.{ 1, "BB" }, it.next().?);
    try std.testing.expectEqualDeep(.{ 2, "ccc" }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}
