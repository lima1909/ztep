const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

pub fn FilterMap(Iter: type, Item: type, To: type) type {
    return struct {
        iter: *Iter,
        filterMapFn: *const fn (Item) ?To,

        pub fn next(self: *@This()) ?To {
            while (self.iter.next()) |item| {
                if (self.filterMapFn(item)) |to| {
                    return to;
                }
            }

            return null;
        }

        pub fn reset(self: *@This()) void {
            var parent: *Iterator(Iter) = @fieldParentPtr("iter", self.iter);
            parent.reset();
        }
    };
}

test "filterMap" {
    var tokensIt = std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' ');
    var it = FilterMap(@TypeOf(tokensIt), []const u8, u8){
        .iter = &tokensIt,
        .filterMapFn = struct {
            fn firstCharUpper(in: []const u8) ?u8 {
                const first = in[0];
                return if (std.ascii.isUpper(first)) first else null;
            }
        }.firstCharUpper,
    };

    try std.testing.expectEqual('B', it.next().?);
    try std.testing.expectEqual('D', it.next().?);
    try std.testing.expectEqual(null, it.next());
}
