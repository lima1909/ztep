const std = @import("std");

const Iterator = @import("iter.zig").Iterator;

/// Create a new Iterator for the given slice.
pub fn fromSlice(comptime slice: anytype) Iterator(Slice(slice)) {
    return .{ .iter = Slice(slice){ .items = slice } };
}

pub fn Slice(slice: anytype) type {
    const Item = switch (@typeInfo(@TypeOf(slice))) {
        .array => |a| a.child,
        .pointer => |p| switch (@typeInfo(p.child)) {
            .array => |a| a.child,
            else => @compileError("not a valid slice type: " ++ @typeName(p)),
        },
        else => @compileError("this is not a valid slice type: " ++ @typeName(slice)),
    };

    return struct {
        items: []const Item,
        front: usize = 0,
        end: usize = slice.len,

        /// next from the front-side
        pub fn next(self: *@This()) ?Item {
            if (self.front >= self.end) return null;

            const item = self.items[self.front];
            self.front += 1;
            return item;
        }

        /// next from the end-side
        pub fn nextBack(self: *@This()) ?Item {
            if (self.front >= self.end) return null;

            self.end -= 1;
            return self.items[self.end];
        }

        pub fn count(self: *@This()) usize {
            const c = self.end - self.front;
            self.front = self.end;
            return c;
        }
    };
}

test "slice count" {
    var it = fromSlice(&[_][]const u8{ "a", "BB", "ccc" }).iter;

    try std.testing.expectEqual(3, it.count());
}

test "slice next" {
    var it = fromSlice(&[_][]const u8{ "a", "BB", "ccc" }).iter;

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);

    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(null, it.nextBack());

    try std.testing.expectEqual(0, it.count());
}

test "slice nextBack" {
    var it = fromSlice(&[_][]const u8{ "a", "BB", "ccc" }).iter;

    try std.testing.expectEqualStrings("ccc", it.nextBack().?);
    try std.testing.expectEqualStrings("BB", it.nextBack().?);
    try std.testing.expectEqualStrings("a", it.nextBack().?);

    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(null, it.nextBack());

    try std.testing.expectEqual(0, it.count());
}

test "slice next and nextBack" {
    var it = fromSlice(&[_][]const u8{ "a", "BB", "ccc" }).iter;

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.nextBack().?);
    try std.testing.expectEqualStrings("BB", it.next().?);

    try std.testing.expectEqual(null, it.nextBack());
    try std.testing.expectEqual(null, it.next());

    try std.testing.expectEqual(0, it.count());
}

test "slice next and nextBack 2" {
    var it = fromSlice(&[_][]const u8{ "a", "BB", "ccc" }).iter;

    try std.testing.expectEqualStrings("ccc", it.nextBack().?);
    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.nextBack().?);

    try std.testing.expectEqual(null, it.nextBack());
    try std.testing.expectEqual(null, it.next());
}

test "slice i32 next and nextBack" {
    var it = fromSlice(&[_]i32{ 1, 2, 3, 4, 5 }).iter;

    try std.testing.expectEqualDeep(5, it.nextBack());
    try std.testing.expectEqualDeep(1, it.next());
    try std.testing.expectEqualDeep(4, it.nextBack());
    try std.testing.expectEqualDeep(2, it.next());
    try std.testing.expectEqualDeep(3, it.nextBack());
    try std.testing.expectEqualDeep(null, it.next());
    try std.testing.expectEqualDeep(null, it.nextBack());
}

test "slice peek first" {
    var it = fromSlice(&[_][]const u8{ "a", "b" }).peekable();

    try std.testing.expectEqualStrings("a", it.peek().?);
    try std.testing.expectEqualStrings("a", it.peek().?);
    try std.testing.expectEqualStrings("a", it.next().?);

    try std.testing.expectEqualStrings("b", it.peek().?);
    try std.testing.expectEqualStrings("b", it.next().?);

    try std.testing.expectEqual(null, it.peek());
    try std.testing.expectEqual(null, it.next());
}

test "slice peek after next" {
    var it = fromSlice(&[_][]const u8{ "a", "b" }).peekable();

    try std.testing.expectEqualStrings("a", it.next().?);

    try std.testing.expectEqualStrings("b", it.peek().?);
    try std.testing.expectEqualStrings("b", it.next().?);

    try std.testing.expectEqual(null, it.peek());
    try std.testing.expectEqual(null, it.next());
}

test "slice peek empty" {
    var it = fromSlice(&[_][]const u8{}).peekable();

    try std.testing.expectEqual(null, it.peek());
    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(null, it.peek());
}
