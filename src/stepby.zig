const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

pub fn StepBy(Iter: type, Item: type) type {
    return struct {
        iter: *Iter,
        parent: *Iterator(Iter),
        step_minus_one: usize,
        first_take: bool = true,

        pub fn init(iter: *Iter, step: usize) @This() {
            return .{
                .iter = iter,
                .parent = @fieldParentPtr("iter", iter),
                .step_minus_one = if (step == 0) 0 else step - 1,
            };
        }

        pub fn next(self: *@This()) ?Item {
            // the first step is allays 0
            const step_size = if (self.first_take) 0 else self.step_minus_one;
            self.first_take = false;

            return self.parent.nth(step_size);
        }
    };
}

test "StepBy" {
    var tokenIt = std.mem.tokenizeScalar(u8, "a b c d e f", ' ');
    var it1 = StepBy(@TypeOf(tokenIt), []const u8).init(&tokenIt, 1);

    try std.testing.expectEqualStrings("a", it1.next().?);
    try std.testing.expectEqualStrings("b", it1.next().?);
    try std.testing.expectEqualStrings("c", it1.next().?);
    try std.testing.expectEqualStrings("d", it1.next().?);
    try std.testing.expectEqualStrings("e", it1.next().?);
    try std.testing.expectEqualStrings("f", it1.next().?);
    try std.testing.expectEqual(null, it1.next());

    tokenIt = std.mem.tokenizeScalar(u8, "a b c d e f", ' ');
    var it2 = StepBy(@TypeOf(tokenIt), []const u8).init(&tokenIt, 2);

    try std.testing.expectEqualStrings("a", it2.next().?);
    try std.testing.expectEqualStrings("c", it2.next().?);
    try std.testing.expectEqualStrings("e", it2.next().?);
    try std.testing.expectEqual(null, it2.next());

    tokenIt = std.mem.tokenizeScalar(u8, "a b c d e f", ' ');
    var it3 = StepBy(@TypeOf(tokenIt), []const u8).init(&tokenIt, 3);

    try std.testing.expectEqualStrings("a", it3.next().?);
    try std.testing.expectEqualStrings("d", it3.next().?);
    try std.testing.expectEqual(null, it3.next());
}
