const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

pub fn TakeWhile(Iter: type, Item: type) type {
    return struct {
        iter: *Iter,
        predicate: *const fn (Item) bool,
        done: bool = false,

        pub fn next(self: *@This()) ?Item {
            if (self.done) return null;

            if (self.iter.next()) |item|
                if (self.predicate(item)) return item;

            self.done = true;
            return null;
        }

        pub fn reset(self: *@This()) void {
            var parent: *Iterator(Iter) = @fieldParentPtr("iter", self.iter);
            parent.reset();
        }
    };
}

test "takeWhile" {
    var tokensIt = std.mem.tokenizeScalar(u8, "x BB ccc", ' ');
    var it = TakeWhile(@TypeOf(tokensIt), []const u8){
        .iter = &tokensIt,
        .predicate = struct {
            fn isLower(in: []const u8) bool {
                return std.ascii.isLower(in[0]);
            }
        }.isLower,
    };

    try std.testing.expectEqualStrings("x", it.next().?);
    try std.testing.expectEqual(null, it.next());
}
