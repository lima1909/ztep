const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

/// Create a Wrapper for an Iterator, which has a next-method with a different name.
/// You can for example, use this Wrapper, if you want to iterate from the end, when the Iterator has a method nextBack.
/// where 'iter' is the Iterator and 'asNextFn' is the iterate method like 'next' with en optional Item as return value.
pub fn toIterator(comptime iter: anytype, asNextFn: anytype) Iterator(ToIterator(iter, asNextFn)) {
    return .{ .iter = ToIterator(iter, asNextFn){} };
}

/// Reverses an iterator’s direction.
/// The given Iterator needs a method: nextBack
pub fn reverse(comptime iter: anytype) Iterator(ToIterator(iter, @TypeOf(iter).nextBack)) {
    return .{ .iter = ToIterator(iter, @TypeOf(iter).nextBack){} };
}

pub fn ToIterator(iter: anytype, asNextFn: anytype) type {
    const Iter = @TypeOf(iter);

    const nextFn = switch (@typeInfo(@TypeOf(asNextFn))) {
        .@"fn" => |func| func,
        else => @compileError("iterator method 'asNextFn' is not a function"),
    };

    const Item = switch (@typeInfo(nextFn.return_type.?)) {
        .optional => std.meta.Child(nextFn.return_type.?),
        else => |ty| @compileError("unsupported iterator method 'asNextFn' return type" ++ @typeName(ty)),
    };

    return struct {
        iter: Iter = iter,
        nextFn: *const fn (*Iter) ?Item = asNextFn,

        pub fn next(self: *@This()) ?Item {
            return self.nextFn(&self.iter);
        }
    };
}

test "iter no next, iterate with backNext" {
    const items = [_][]const u8{ "a", "bb", "ccc" };
    var it = reverse(@import("slice.zig").Slice(items){ .items = &items })
        .filter(
        struct {
            fn removeBB(item: []const u8) bool {
                return !std.mem.eql(u8, item, "bb");
            }
        }.removeBB,
    );

    try std.testing.expectEqual("ccc", it.next().?);
    try std.testing.expectEqual("a", it.next().?);
    try std.testing.expectEqual(null, it.next());
}
