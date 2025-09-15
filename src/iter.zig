const std = @import("std");

const ArrayChunks = @import("array_chunks.zig").ArrayChunks;
const Chain = @import("chain.zig").Chain;
const Enumerate = @import("enumerate.zig").Enumerate;
const Filter = @import("filter.zig").Filter;
const FilterMap = @import("filter_map.zig").FilterMap;
const Inspect = @import("inspect.zig").Inspect;
const Map = @import("map.zig").Map;
const Peekable = @import("peekable.zig").Peekable;
const Result = @import("result.zig").Result;
const Skip = @import("skip.zig").Skip;
const StepBy = @import("stepby.zig").StepBy;
const Take = @import("take.zig").Take;
const TakeWhile = @import("take_while.zig").TakeWhile;
const Zip = @import("zip.zig").Zip;

/// Create a Wrapper (extension) for the given Iterator.
/// The given Iterator must have a method next with an optional return value (without error).
pub fn extend(iter: anytype) Iterator(@TypeOf(iter)) {
    return Iterator(@TypeOf(iter)){ .iter = iter };
}

/// Is the Iterator Wrapper with extended methods, like filter, map, enumerate ...
pub fn Iterator(Iter: type) type {
    if (!std.meta.hasFn(Iter, "next"))
        @compileError("missing iterator method 'next' for: " ++ @typeName(Iter));

    const nextFn = switch (@typeInfo(@TypeOf(Iter.next))) {
        .@"fn" => |func| func,
        else => @compileError("iterator method 'next' is not a function"),
    };

    const Item = switch (@typeInfo(nextFn.return_type.?)) {
        .optional => std.meta.Child(nextFn.return_type.?),
        else => |ty| @compileError("unsupported iterator method 'next' return type" ++ @typeName(ty)),
    };

    return struct {
        iter: Iter,

        pub fn next(self: *@This()) ?Item {
            return self.iter.next();
        }

        pub fn reset(self: *const @This()) void {
            @constCast(self).iter.reset();
        }

        /// Transforms one iterator into another by a given mapping function.
        pub fn map(self: *const @This(), To: type, mapFn: *const fn (Item) To) Iterator(Map(Iter, Item, To)) {
            return .{ .iter = .init(&@constCast(self).iter, mapFn) };
        }

        /// Creates an iterator which uses a function to determine if an element should be yielded.
        pub fn filter(self: *const @This(), filterFn: *const fn (Item) bool) Iterator(Filter(Iter, Item)) {
            return .{ .iter = .init(&@constCast(self).iter, filterFn) };
        }

        /// Creates an iterator that both filters and maps in one call.
        pub fn filterMap(self: *const @This(), To: type, filterMapFn: *const fn (Item) ?To) Iterator(FilterMap(Iter, Item, To)) {
            return .{ .iter = .init(&@constCast(self).iter, filterMapFn) };
        }

        /// Creates an iterator that yields the first n elements, or fewer if the underlying iterator ends sooner.
        pub fn take(self: *const @This(), n: usize) Iterator(Take(Iter, Item)) {
            return .{ .iter = .init(&@constCast(self).iter, n) };
        }

        /// Creates an iterator which calls the predicate on each element, and yield elements while it returns true.
        /// So you can stop the iteration.
        pub fn takeWhile(self: *const @This(), predicate: *const fn (Item) bool) Iterator(TakeWhile(Iter, Item)) {
            return .{ .iter = .init(&@constCast(self).iter, predicate) };
        }

        /// Returns an iterator over N elements of the iterator at a time.
        /// The chunks do not overlap. If N does not divide the length of the iterator, then the last up to N-1 elements
        /// will be omitted and can be retrieved from the .remainder field of the iterator.
        pub fn arrayChunks(self: *const @This(), comptime n: usize) Iterator(ArrayChunks(Iter, Item, n)) {
            return .{ .iter = .init(&@constCast(self).iter) };
        }

        /// Creates an iterator which gives the current iteration count as well as the next value.
        pub fn enumerate(self: *const @This()) Iterator(Enumerate(Iter, Item)) {
            return .{ .iter = .init(&@constCast(self).iter) };
        }

        /// This iterator do nothing, the purpose is for debugging.
        /// Maybe to printing the current Item.
        /// .intercept(struct {
        ///     fn print(item: Item) Item {
        ///         std.debug.print("{}\n", .{item});
        ///     }
        /// }.print)
        pub fn inspect(self: *const @This(), inspectFn: *const fn (Item) Item) Iterator(Inspect(Iter, Item)) {
            return .{ .iter = .init(&@constCast(self).iter, inspectFn) };
        }

        /// Folds every element into an accumulator by applying an operation, returning the final result.
        pub fn fold(self: *const @This(), To: type, init: To, foldFn: *const fn (To, Item) To) To {
            var iter = &@constCast(self).iter;

            var accum = init;
            while (iter.next()) |item| {
                accum = foldFn(accum, item);
            }
            return accum;
        }

        /// Reduces the elements to a single one, by repeatedly applying a reducing function.
        pub fn reduce(self: *const @This(), reduceFn: *const fn (Item, Item) Item) ?Item {
            var iter = &@constCast(self).iter;

            var accum = iter.next() orelse return null;
            while (iter.next()) |item| {
                accum = reduceFn(accum, item);
            }
            return accum;
        }

        /// Creates an iterator that skips the first n elements.
        pub fn skip(self: *const @This(), n: usize) Iterator(Skip(Iter, Item)) {
            return .{ .iter = .init(&@constCast(self).iter, n) };
        }

        /// Creates an iterator starting at the same point, but stepping by the given amount at each iteration.
        pub fn stepBy(self: *const @This(), comptime step: usize) Iterator(StepBy(Iter, Item)) {
            return .{ .iter = .init(&@constCast(self).iter, step) };
        }

        /// Takes two iterators and creates a new iterator over both in sequence.
        pub fn chain(self: *const @This(), otherIter: anytype) Iterator(Chain(Iter, @TypeOf(otherIter), Item)) {
            return .{ .iter = .{
                .first = &@constCast(self).iter,
                .second = otherIter,
            } };
        }

        /// Zips up’ two iterators into a single iterator of pairs.
        pub fn zip(self: *const @This(), otherIter: anytype) Iterator(Zip(Iter, @TypeOf(otherIter), Item)) {
            return .{ .iter = .{
                .first = &@constCast(self).iter,
                .second = otherIter,
            } };
        }

        /// Creates an iterator which can use the peek methods to look at the next element of the iterator without consuming it.
        pub fn peekable(self: *const @This()) Peekable(Iter, Item) {
            return .init(&@constCast(self).iter);
        }

        /// Collects all the items from an iterator into a given collection (like: ArrayList, BoundedArray, HashMap, ...).
        pub fn tryCollectInto(
            self: *const @This(),
            containerPtr: anytype,
            iterFn: *const fn (@TypeOf(containerPtr), Item) anyerror!void,
        ) anyerror!usize {
            var iter = &@constCast(self).iter;

            var index: usize = 0;
            while (iter.next()) |item| : (index += 1) {
                try iterFn(containerPtr, item);
            }
            return index;
        }

        /// Collects all the items from an iterator into a given Buffer.
        pub fn tryCollect(self: *const @This(), buffer: []Item) anyerror!usize {
            var iter = &@constCast(self).iter;

            var index: usize = 0;
            const len = buffer.len;

            while (iter.next()) |item| : (index += 1) {
                if (index == len) return error.IndexOutOfBound;

                buffer[index] = item;
            }

            return index;
        }

        /// Calls a function fn(Item) on each element of an iterator.
        pub fn forEach(self: *const @This(), forEachFn: *const fn (Item) void) void {
            var iter = &@constCast(self).iter;

            while (iter.next()) |item| {
                forEachFn(item);
            }
        }

        /// An iterator method that applies a fallible function to each item in the iterator,
        /// stopping at the first error and returning that error.
        pub fn tryForEach(self: *const @This(), forEachFn: *const fn (Item) anyerror!void) Result(Iter, Item) {
            var iter = &@constCast(self).iter;

            while (iter.next()) |item| {
                forEachFn(item) catch |err| {
                    return Result(Iter, Item){
                        .err = err,
                        .err_item = item,
                        .iter = iter,
                    };
                };
            }

            return Result(Iter, Item){ .iter = iter };
        }

        /// Searches for an element of an iterator that satisfies a predicate.
        pub fn find(self: *const @This(), predicateFn: *const fn (Item) bool) ?Item {
            var iter = &@constCast(self).iter;

            while (iter.next()) |item| {
                if (predicateFn(item)) {
                    return item;
                }
            }
            return null;
        }

        /// Consumes the iterator, returning the last element.
        pub fn last(self: *const @This()) ?Item {
            var iter = &@constCast(self).iter;

            var item: ?Item = null;
            while (iter.next()) |i| : (item = i) {}
            return item;
        }

        /// Consumes the iterator, returning the nth element.
        pub fn nth(self: *const @This(), n: usize) ?Item {
            var iter = &@constCast(self).iter;

            if (std.meta.hasMethod(Iter, "nth"))
                return iter.nth(n);

            var i: usize = 0;
            while (iter.next()) |item| : (i += 1) {
                if (i == n) {
                    return item;
                }
            }
            return null;
        }

        /// Consumes the iterator, counting the number of iterations and returning it.
        pub fn count(self: *const @This()) usize {
            var iter = &@constCast(self).iter;

            if (std.meta.hasMethod(Iter, "count"))
                return iter.count();

            var counter: usize = 0;
            while (iter.next() != null) : (counter += 1) {}
            return counter;
        }
    };
}
