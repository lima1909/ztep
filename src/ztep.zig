const std = @import("std");
const iters = @import("iters.zig");

/// Create a Wrapper (extension) for the given Iterator.
/// The given Iterator must have a method next with an optional return value (without error).
pub fn extend(iter: anytype) Iterator(@TypeOf(iter)) {
    return Iterator(@TypeOf(iter)){ .iter = iter };
}

/// Create a new Iterator for the given slice.
pub fn fromSlice(comptime slice: anytype) Iterator(Slice(slice)) {
    return Iterator(Slice(slice)){ .iter = Slice(slice){ .items = slice } };
}

/// Is the Iterator Wrapper with extended methods, like filter, map, enumerate ...
pub fn Iterator(Iter: type) type {
    if (!@hasDecl(Iter, "next"))
        @compileError("missing iterator method 'next'");

    const nextFn = switch (@typeInfo(@TypeOf(Iter.next))) {
        .@"fn" => |func| func,
        else => @compileError("iterator method 'next' is not a function"),
    };

    const Item = switch (@typeInfo(nextFn.return_type.?)) {
        .error_union => |eu| switch (@typeInfo(eu.payload)) {
            .Optional => |opt| opt.child,
        },
        .optional => std.meta.Child(nextFn.return_type.?),
        else => |ty| @compileError("unsupported iterator method 'next' return type" ++ @typeName(ty)),
    };

    return struct {
        /// Returns the original (wrapped) Iterator for using this methods.
        iter: Iter,

        pub fn next(self: *@This()) ?Item {
            return self.iter.next();
        }

        /// Transforms one iterator into another by a given mapping function.
        pub fn map(self: *const @This(), To: type, mapFn: *const fn (Item) To) Iterator(iters.Map(Iter, Item, To)) {
            return extend(iters.Map(Iter, Item, To){
                .it = &@constCast(self).iter,
                .mapFn = mapFn,
            });
        }

        /// Creates an iterator which uses a function to determine if an element should be yielded.
        pub fn filter(self: *const @This(), filterFn: *const fn (Item) bool) Iterator(iters.Filter(Iter, Item)) {
            return extend(iters.Filter(Iter, Item){
                .it = &@constCast(self).iter,
                .filterFn = filterFn,
            });
        }

        /// Creates an iterator which gives the current iteration count as well as the next value.
        pub fn enumerate(self: *const @This()) Iterator(iters.Enumerate(Iter, Item)) {
            return extend(iters.Enumerate(Iter, Item){
                .it = &@constCast(self).iter,
            });
        }

        /// This iterator do nothing, the purpose is for debugging.
        /// Maybe to printing the current Item.
        /// .intercept(struct {
        ///     fn print(item: Item) Item {
        ///         std.debug.print("{}\n", .{item});
        ///     }
        /// }.print)
        pub fn inspect(self: *const @This(), inspectFn: *const fn (Item) Item) Iterator(iters.Inspect(Iter, Item)) {
            return extend(iters.Inspect(Iter, Item){
                .it = &@constCast(self).iter,
                .inspectFn = inspectFn(Item),
            });
        }

        /// Folds every element into an accumulator by applying an operation, returning the final result.
        pub fn fold(self: *const @This(), To: type, init: To, foldFn: *const fn (To, Item) To) To {
            var it = &@constCast(self).iter;

            var accum = init;
            while (it.next()) |item| {
                accum = foldFn(accum, item);
            }
            return accum;
        }

        /// Creates an iterator that skips the first n elements.
        pub fn skip(self: *const @This(), n: usize) Iterator(iters.Skip(Iter, Item)) {
            return extend(iters.Skip(Iter, Item){
                .it = &@constCast(self).iter,
                .n = n,
            });
        }

        /// Creates an iterator that yields the first n elements, or fewer if the underlying iterator ends sooner.
        pub fn take(self: *const @This(), n: usize) Iterator(iters.Take(Iter, Item)) {
            return extend(iters.Take(Iter, Item){
                .it = &@constCast(self).iter,
                .n = n,
            });
        }

        /// Collects all the items from an iterator into a given collection (like: ArrayList, BoundedArray, HashMap, ...).
        pub fn tryCollectInto(
            self: *const @This(),
            containerPtr: anytype,
            iterFn: *const fn (@TypeOf(containerPtr), Item) anyerror!void,
        ) anyerror!usize {
            var it = &@constCast(self).iter;

            var index: usize = 0;
            while (it.next()) |item| {
                try iterFn(containerPtr, item);
                index += 1;
            }
            return index;
        }

        /// Collects all the items from an iterator into a given Buffer.
        pub fn tryCollect(self: *const @This(), buffer: []Item) anyerror!usize {
            var it = &@constCast(self).iter;

            var index: usize = 0;
            const len = buffer.len;

            while (it.next()) |item| {
                if (index == len) return error.IndexOutOfBound;

                buffer[index] = item;
                index += 1;
            }

            return index;
        }

        /// Calls a function fn(Item) on each element of an iterator.
        pub fn forEach(self: *const @This(), forEachFn: *const fn (Item) void) void {
            var it = &@constCast(self).iter;

            while (it.next()) |item| {
                forEachFn(item);
            }
        }

        /// Consumes the iterator, returning the last element.
        pub fn last(self: *const @This()) ?Item {
            var it = &@constCast(self).iter;

            var item: ?Item = null;
            while (it.next()) |i| {
                item = i;
            }
            return item;
        }

        /// Consumes the iterator, returning the nth element.
        pub fn nth(self: *const @This(), n: usize) ?Item {
            var it = &@constCast(self).iter;

            var i: usize = 0;
            while (it.next()) |item| {
                if (i == n) {
                    return item;
                }
                i += 1;
            }
            return null;
        }

        /// Consumes the iterator, counting the number of iterations and returning it.
        pub fn count(self: *const @This()) usize {
            var it = &@constCast(self).iter;

            var counter: usize = 0;
            while (it.next() != null) {
                counter += 1;
            }
            return counter;
        }
    };
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
    };
}

test "slice next" {
    var it = fromSlice(&[_][]const u8{ "a", "BB", "ccc" }).iter;

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);

    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(null, it.nextBack());
}

test "slice nextBack" {
    var it = fromSlice(&[_][]const u8{ "a", "BB", "ccc" }).iter;

    try std.testing.expectEqualStrings("ccc", it.nextBack().?);
    try std.testing.expectEqualStrings("BB", it.nextBack().?);
    try std.testing.expectEqualStrings("a", it.nextBack().?);

    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(null, it.nextBack());
}

test "slice next and nextBack" {
    var it = fromSlice(&[_][]const u8{ "a", "BB", "ccc" }).iter;

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.nextBack().?);
    try std.testing.expectEqualStrings("BB", it.next().?);

    try std.testing.expectEqual(null, it.nextBack());
    try std.testing.expectEqual(null, it.next());
}

test "slice next and nextBack 2" {
    var it = fromSlice(&[_][]const u8{ "a", "BB", "ccc" }).iter;

    try std.testing.expectEqualStrings("ccc", it.nextBack().?);
    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.nextBack().?);

    try std.testing.expectEqual(null, it.nextBack());
    try std.testing.expectEqual(null, it.next());
}

test {
    _ = @import("./iters.zig");
    _ = @import("./tests.zig");
}
