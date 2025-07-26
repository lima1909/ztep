const std = @import("std");
const iters = @import("iters.zig");

/// Create a Wrapper (extension) for the given Iterator.
/// The given Iterator must have a method next with an optional return value (without error).
pub fn extend(iter: anytype) Iterator(@TypeOf(iter)) {
    return Iterator(@TypeOf(iter)){ .it = iter };
}

/// Create a new Iterator for the given slice.
pub fn fromSlice(comptime slice: anytype) Iterator(Slice(slice)) {
    return Iterator(Slice(slice)){ .it = Slice(slice){ .items = slice } };
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
        it: Iter,

        pub fn next(self: *@This()) ?Item {
            return self.it.next();
        }

        /// Transforms one iterator into another by a given mapping function.
        pub fn map(self: *const @This(), To: type, mapFn: *const fn (Item) To) Iterator(iters.Map(Iter, Item, To)) {
            return extend(iters.Map(Iter, Item, To){
                .it = &@constCast(self).it,
                .mapFn = mapFn,
            });
        }

        /// Creates an iterator which uses a function to determine if an element should be yielded.
        pub fn filter(self: *const @This(), filterFn: *const fn (Item) bool) Iterator(iters.Filter(Iter, Item)) {
            return extend(iters.Filter(Iter, Item){
                .it = &@constCast(self).it,
                .filterFn = filterFn,
            });
        }

        /// Creates an iterator which gives the current iteration count as well as the next value.
        pub fn enumerate(self: *const @This()) Iterator(iters.Enumerate(Iter, Item)) {
            return extend(iters.Enumerate(Iter, Item){
                .it = &@constCast(self).it,
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
                .it = &@constCast(self).it,
                .inspectFn = inspectFn(Item),
            });
        }

        /// Folds every element into an accumulator by applying an operation, returning the final result.
        pub fn fold(self: *const @This(), To: type, init: To, foldFn: *const fn (To, Item) To) To {
            var it = &@constCast(self).it;
            var accum = init;

            while (it.next()) |item| {
                accum = foldFn(accum, item);
            }

            return accum;
        }

        /// Consumes the iterator, counting the number of iterations and returning it.
        pub fn count(self: *const @This()) usize {
            var it = &@constCast(self).it;
            var counter: usize = 0;

            while (it.next() != null) {
                counter += 1;
            }

            return counter;
        }

        /// Returns the original (wrapped) Iterator for using this methods.
        pub fn iter(self: *@This()) *Iter {
            return &self.it;
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
        index: usize = 0,

        pub fn next(self: *@This()) ?Item {
            if (self.index == self.items.len) return null;

            defer self.index += 1;
            return self.items[self.index];
        }
    };
}

test {
    _ = @import("./iters.zig");
    _ = @import("./tests.zig");
}
