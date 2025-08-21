const std = @import("std");
const iters = @import("iters.zig");

/// Create a Wrapper (extension) for the given Iterator.
/// The given Iterator must have a method next with an optional return value (without error).
pub fn extend(iter: anytype) Iterator(@TypeOf(iter)) {
    return Iterator(@TypeOf(iter)){ .iter = iter };
}

/// Is the Iterator Wrapper with extended methods, like filter, map, enumerate ...
pub fn Iterator(Iter: type) type {
    if (!std.meta.hasFn(Iter, "next"))
        @compileError("missing iterator method 'next'");

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

        /// Transforms one iterator into another by a given mapping function.
        pub fn map(self: *const @This(), To: type, mapFn: *const fn (Item) To) Iterator(iters.Map(Iter, Item, To)) {
            return .{ .iter = .{
                .iter = &@constCast(self).iter,
                .mapFn = mapFn,
            } };
        }

        /// Creates an iterator which uses a function to determine if an element should be yielded.
        pub fn filter(self: *const @This(), filterFn: *const fn (Item) bool) Iterator(iters.Filter(Iter, Item)) {
            return .{ .iter = .{
                .iter = &@constCast(self).iter,
                .filterFn = filterFn,
            } };
        }

        /// Creates an iterator that both filters and maps in one call.
        pub fn filterMap(self: *const @This(), To: type, filterMapFn: *const fn (Item) ?To) Iterator(iters.FilterMap(Iter, Item, To)) {
            return .{ .iter = .{
                .iter = &@constCast(self).iter,
                .filterMapFn = filterMapFn,
            } };
        }

        /// Creates an iterator which gives the current iteration count as well as the next value.
        pub fn enumerate(self: *const @This()) Iterator(iters.Enumerate(Iter, Item)) {
            return .{ .iter = .{
                .iter = &@constCast(self).iter,
            } };
        }

        /// This iterator do nothing, the purpose is for debugging.
        /// Maybe to printing the current Item.
        /// .intercept(struct {
        ///     fn print(item: Item) Item {
        ///         std.debug.print("{}\n", .{item});
        ///     }
        /// }.print)
        pub fn inspect(self: *const @This(), inspectFn: *const fn (Item) Item) Iterator(iters.Inspect(Iter, Item)) {
            return .{ .iter = .{
                .iter = &@constCast(self).iter,
                .inspectFn = inspectFn(Item),
            } };
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
        pub fn skip(self: *const @This(), n: usize) Iterator(iters.Skip(Iter, Item)) {
            return .{ .iter = .{
                .iter = &@constCast(self).iter,
                .n = n,
            } };
        }

        /// Creates an iterator that yields the first n elements, or fewer if the underlying iterator ends sooner.
        pub fn take(self: *const @This(), n: usize) Iterator(iters.Take(Iter, Item)) {
            return .{ .iter = .{
                .iter = &@constCast(self).iter,
                .n = n,
            } };
        }

        /// Creates an iterator starting at the same point, but stepping by the given amount at each iteration.
        pub fn stepBy(self: *const @This(), comptime step: usize) Iterator(iters.StepBy(Iter, Item, step)) {
            return .{ .iter = .{
                .iter = &@constCast(self).iter,
            } };
        }

        /// Takes two iterators and creates a new iterator over both in sequence.
        pub fn chain(self: *const @This(), otherIter: anytype) Iterator(iters.Chain(Iter, @TypeOf(otherIter), Item)) {
            return .{ .iter = .{
                .first = &@constCast(self).iter,
                .second = otherIter,
            } };
        }

        /// Zips up’ two iterators into a single iterator of pairs.
        pub fn zip(self: *const @This(), otherIter: anytype) Iterator(iters.Zip(Iter, @TypeOf(otherIter), Item)) {
            return .{ .iter = .{
                .first = &@constCast(self).iter,
                .second = otherIter,
            } };
        }

        /// Creates an iterator which can use the peek methods to look at the next element of the iterator without consuming it.
        pub fn peekable(self: *const @This()) iters.Peekable(Iter, Item) {
            return .{ .iter = &@constCast(self).iter };
        }

        /// Collects all the items from an iterator into a given collection (like: ArrayList, BoundedArray, HashMap, ...).
        pub fn tryCollectInto(
            self: *const @This(),
            containerPtr: anytype,
            iterFn: *const fn (@TypeOf(containerPtr), Item) anyerror!void,
        ) anyerror!usize {
            var iter = &@constCast(self).iter;

            var index: usize = 0;
            while (iter.next()) |item| {
                try iterFn(containerPtr, item);
                index += 1;
            }
            return index;
        }

        /// Collects all the items from an iterator into a given Buffer.
        pub fn tryCollect(self: *const @This(), buffer: []Item) anyerror!usize {
            var iter = &@constCast(self).iter;

            var index: usize = 0;
            const len = buffer.len;

            while (iter.next()) |item| {
                if (index == len) return error.IndexOutOfBound;

                buffer[index] = item;
                index += 1;
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

            var counter: usize = 0;
            while (iter.next() != null) : (counter += 1) {}
            return counter;
        }
    };
}

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

/// Create a new Iterator for the given range, from start to exclude end.
pub fn range(Item: type, start: Item, end: Item) Iterator(Range(Item)) {
    return .{ .iter = Range(Item){
        .start = start,
        .end = end,
    } };
}

/// Create a new Iterator for the given range, like range, but the end is inclusive.
pub fn rangeIncl(Item: type, start: Item, end: Item) Iterator(Range(Item)) {
    return .{ .iter = Range(Item){
        .start = start,
        .end = end,
        .inclusive = true,
    } };
}

pub fn Range(Item: type) type {
    return struct {
        start: Item,
        end: Item,
        inclusive: bool = false,

        /// next from the front-side
        pub fn next(self: *@This()) ?Item {
            if (self.start > self.end or (!self.inclusive and self.start == self.end)) return null;

            const start = self.start;
            self.start += 1;
            return start;
        }

        /// next from the end-side
        pub fn nextBack(self: *@This()) ?Item {
            if (self.start > self.end or (!self.inclusive and self.start == self.end)) return null;

            self.end -= 1;
            return self.end;
        }
    };
}

test "range u8" {
    var buffer: [4]u8 = undefined;
    const n = try range(u8, 'a', 'd').tryCollect(&buffer);
    try std.testing.expectEqualStrings("abc", buffer[0..n]);
}

test "rangeIncl char" {
    var buffer: [4]u8 = undefined;
    const n = try rangeIncl(u8, 'a', 'd').tryCollect(&buffer);
    try std.testing.expectEqualStrings("abcd", buffer[0..n]);
}

test "rangeIncl i32" {
    var buffer: [10]i32 = undefined;
    const n = try rangeIncl(i32, 1, 6).tryCollect(&buffer);
    try std.testing.expectEqualDeep(&[_]i32{ 1, 2, 3, 4, 5, 6 }, buffer[0..n]);
}

test "range i32" {
    var buffer: [10]i32 = undefined;
    const n = try range(i32, 1, 6).tryCollect(&buffer);
    try std.testing.expectEqualDeep(&[_]i32{ 1, 2, 3, 4, 5 }, buffer[0..n]);
}

test "range i32 next" {
    var it = range(i32, 1, 5).iter;

    try std.testing.expectEqualDeep(1, it.next());
    try std.testing.expectEqualDeep(2, it.next());
    try std.testing.expectEqualDeep(3, it.next());
    try std.testing.expectEqualDeep(4, it.next());
    try std.testing.expectEqualDeep(null, it.next());
    try std.testing.expectEqualDeep(null, it.nextBack());
}

test "range i32 back" {
    var it = range(i32, 1, 5).iter;

    try std.testing.expectEqualDeep(4, it.nextBack());
    try std.testing.expectEqualDeep(3, it.nextBack());
    try std.testing.expectEqualDeep(2, it.nextBack());
    try std.testing.expectEqualDeep(1, it.nextBack());
    try std.testing.expectEqualDeep(null, it.next());
    try std.testing.expectEqualDeep(null, it.nextBack());
}

test "range i32 next and back" {
    var it = range(i32, 1, 5).iter;

    try std.testing.expectEqualDeep(4, it.nextBack());
    try std.testing.expectEqualDeep(1, it.next());
    try std.testing.expectEqualDeep(3, it.nextBack());
    try std.testing.expectEqualDeep(2, it.next());
    try std.testing.expectEqualDeep(null, it.next());
    try std.testing.expectEqualDeep(null, it.nextBack());
}

test "range i32 filter " {
    var it = range(i32, 1, 10).filter(struct {
        fn isEven(i: i32) bool {
            return @mod(i, 2) == 0;
        }
    }.isEven);

    try std.testing.expectEqualDeep(2, it.next());
    try std.testing.expectEqualDeep(4, it.next());
    try std.testing.expectEqualDeep(6, it.next());
    try std.testing.expectEqualDeep(8, it.next());
}

test "range i32 start > end" {
    var it = range(i32, 5, 1).iter;

    try std.testing.expectEqualDeep(null, it.next());
    try std.testing.expectEqualDeep(null, it.nextBack());
}

/// Creates an custom iterator with the initialized (start) value and the provided (next) function.
pub fn fromFn(Item: type, init: Item, nextFn: *const fn (*Item) ?Item) Iterator(FromFn(Item)) {
    return .{ .iter = FromFn(Item){
        .value = init,
        .callback = nextFn,
    } };
}

pub fn FromFn(Item: type) type {
    return struct {
        value: Item,
        callback: *const fn (*Item) ?Item,

        pub fn next(self: *@This()) ?Item {
            return self.callback(&self.value);
        }
    };
}

test "fromFn, simple counter until 5" {
    var it = fromFn(i32, 0, struct {
        fn next(v: *i32) ?i32 {
            v.* += 1;
            if (v.* <= 5)
                return v.*
            else
                return null;
        }
    }.next)
        .filter(struct {
        fn isEven(i: i32) bool {
            return @mod(i, 2) == 0;
        }
    }.isEven);

    try std.testing.expectEqual(2, it.next().?);
    try std.testing.expectEqual(4, it.next().?);
    try std.testing.expectEqual(null, it.next());
}

/// Creates an iterator that yields nothing.
pub fn empty(Item: type, value: anytype) Iterator(RepeatN(Item)) {
    return .{ .iter = RepeatN(Item){ .item = value, .ntimes = 0 } };
}

/// Creates an iterator that yields an element exactly once.
pub fn once(Item: type, value: anytype) Iterator(RepeatN(Item)) {
    return .{ .iter = RepeatN(Item){ .item = value, .ntimes = 1 } };
}

/// Creates a new iterator that N times repeats a given value.
pub fn repeatN(Item: type, value: anytype, n: usize) Iterator(RepeatN(Item)) {
    return .{ .iter = RepeatN(Item){ .item = value, .ntimes = n } };
}

pub fn RepeatN(Item: type) type {
    return struct {
        item: Item,
        ntimes: usize,

        pub fn next(self: *@This()) ?Item {
            if (self.ntimes == 0) return null;

            self.ntimes -= 1;
            return self.item;
        }
    };
}

test "empty with filter" {
    var it = empty(u8, 'x');
    try std.testing.expectEqual(null, it.next());

    var it2 = empty(u8, 'a').filter(std.ascii.isAlphabetic);
    try std.testing.expectEqual(null, it2.next());

    it2 = empty(u8, '1').filter(std.ascii.isAlphabetic);
    try std.testing.expectEqual(null, it2.next());
}

test "once with filter" {
    var it = once(u8, 'x');
    try std.testing.expectEqual('x', it.next().?);
    try std.testing.expectEqual(null, it.next());

    var it2 = once(u8, 'a').filter(std.ascii.isAlphabetic);
    try std.testing.expectEqual('a', it2.next().?);
    try std.testing.expectEqual(null, it2.next());

    it2 = once(u8, '1').filter(std.ascii.isAlphabetic);
    try std.testing.expectEqual(null, it2.next());
}

test "repeatN" {
    var it = repeatN(i32, 42, 4);
    try std.testing.expectEqual(42, it.next().?);
    try std.testing.expectEqual(42, it.next().?);
    try std.testing.expectEqual(42, it.next().?);
    try std.testing.expectEqual(42, it.next().?);
    try std.testing.expectEqual(null, it.next());

    const ptr: *const i32 = &42;
    var it2 = repeatN(*const i32, ptr, 1);
    try std.testing.expectEqual(ptr, it2.next().?);
    try std.testing.expectEqual(null, it2.next());

    var it3 = repeatN([]const u8, "abc_xyz", std.math.maxInt(usize));
    for (0..1000) |_| {
        try std.testing.expectEqualStrings("abc_xyz", it3.next().?);
    }
}

test "repeatN filter" {
    var it = repeatN(u8, 'a', 2).filter(std.ascii.isAlphabetic);
    try std.testing.expectEqual('a', it.next().?);
    try std.testing.expectEqual('a', it.next().?);
    try std.testing.expectEqual(null, it.next());

    it = repeatN(u8, '1', 2).filter(std.ascii.isAlphabetic);
    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(null, it.next());
}

/// Extend an Iterator which has a next-method, which returns an error_union (next() anyerror!Item).
///
/// If handleError returns:
///   - true means continue (ignore error and call next)
///   - false, interrupt next and returns null
pub fn extendWithError(iterPtr: anytype, handleError: ?*const fn (anyerror) bool) Iterator(IterWithError(@TypeOf(iterPtr))) {
    return .{ .iter = IterWithError(@TypeOf(iterPtr)){
        .iter = iterPtr,
        .handleError = handleError orelse IterWithError(@TypeOf(iterPtr)).stopOnError,
    } };
}

pub fn IterWithError(Iter: type) type {
    const IterType = switch (@typeInfo(Iter)) {
        .pointer => |p| p.child,
        else => Iter,
    };

    if (!@hasDecl(IterType, "next"))
        @compileError("missing iterator method 'next'");

    const nextFn = switch (@typeInfo(@TypeOf(IterType.next))) {
        .@"fn" => |func| func,
        else => @compileError("iterator method 'next' is not a function"),
    };

    const Item = switch (@typeInfo(nextFn.return_type.?)) {
        .error_union => |eu| switch (@typeInfo(eu.payload)) {
            .optional => |opt| opt.child,
            else => |ty| @compileError("unsupported iterator method 'next' return type" ++ @typeName(ty)),
        },
        else => |ty| @compileError("unsupported iterator method 'next' return type" ++ @typeName(ty)),
    };

    return struct {
        iter: Iter,
        handleError: *const fn (anyerror) bool,
        stop: bool = false,

        pub fn next(self: *@This()) ?Item {
            if (self.stop) return null;

            while (true) {
                const item = self.iter.next() catch |err| {
                    // execute the error handler
                    // if return false, then break, else continue
                    if (!self.handleError(err)) {
                        self.stop = true;
                        return null;
                    }

                    continue;
                };

                return item orelse return null;
            }
        }

        pub fn stopOnError(_: anyerror) bool {
            return false;
        }
    };
}

test "iterator with error" {
    const dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
    var walker = try dir.walk(std.testing.allocator);
    defer walker.deinit();

    const build = extendWithError(&walker, null).find(struct {
        fn find(entry: std.fs.Dir.Walker.Entry) bool {
            if (std.mem.eql(u8, "build.zig", entry.basename)) return true else return false;
        }
    }.find);

    try std.testing.expectEqualStrings("build.zig", build.?.basename);
}

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
    var it = reverse(Slice(items){ .items = &items })
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

test {
    _ = @import("./iters.zig");
    _ = @import("./tests.zig");
}
