const std = @import("std");

pub fn StepBy(Iter: type, Item: type, step: usize) type {
    return struct {
        iter: *Iter,
        step_minus_one: usize = step - 1,
        first_take: bool = true,

        pub fn next(self: *@This()) ?Item {
            // the first step is allays 0
            const step_size = if (self.first_take) 0 else self.step_minus_one;
            self.first_take = false;

            var i: usize = 0;
            while (self.iter.next()) |item| : (i += 1) {
                if (i == step_size) {
                    return item;
                }
            }
            return null;
        }
    };
}

test "StepBy" {
    var tokenIt = std.mem.tokenizeScalar(u8, "a b c d e f", ' ');
    var it1 = StepBy(@TypeOf(tokenIt), []const u8, 1){ .iter = &tokenIt };

    try std.testing.expectEqualStrings("a", it1.next().?);
    try std.testing.expectEqualStrings("b", it1.next().?);
    try std.testing.expectEqualStrings("c", it1.next().?);
    try std.testing.expectEqualStrings("d", it1.next().?);
    try std.testing.expectEqualStrings("e", it1.next().?);
    try std.testing.expectEqualStrings("f", it1.next().?);
    try std.testing.expectEqual(null, it1.next());

    tokenIt = std.mem.tokenizeScalar(u8, "a b c d e f", ' ');
    var it2 = StepBy(@TypeOf(tokenIt), []const u8, 2){ .iter = &tokenIt };

    try std.testing.expectEqualStrings("a", it2.next().?);
    try std.testing.expectEqualStrings("c", it2.next().?);
    try std.testing.expectEqualStrings("e", it2.next().?);
    try std.testing.expectEqual(null, it2.next());

    tokenIt = std.mem.tokenizeScalar(u8, "a b c d e f", ' ');
    var it3 = StepBy(@TypeOf(tokenIt), []const u8, 3){ .iter = &tokenIt };

    try std.testing.expectEqualStrings("a", it3.next().?);
    try std.testing.expectEqualStrings("d", it3.next().?);
    try std.testing.expectEqual(null, it3.next());
}
