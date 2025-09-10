const std = @import("std");
const extend = @import("ztep.zig").extend;
const extendWithError = @import("ztep.zig").extendWithError;
const fromSlice = @import("ztep.zig").fromSlice;
const range = @import("ztep.zig").range;
const Iterator = @import("ztep.zig").Iterator;

const is_zig_0_14 = if (std.meta.hasMethod(std.ArrayList(u8), "appendBounded"))
    false
else
    true;

fn firstChar(in: []const u8) u8 {
    return in[0];
}

fn isFirstCharUpper(in: []const u8) bool {
    return std.ascii.isUpper(in[0]);
}

fn isFirstCharUpperToChar(in: []const u8) ?u8 {
    const first = in[0];
    return if (std.ascii.isUpper(first)) first else null;
}

fn addLen(accum: usize, in: []const u8) usize {
    return accum + in.len;
}

test "extend" {
    const csv = "a,b,c\nd,e,f";
    var it = extend(std.mem.tokenizeScalar(u8, csv, '\n'))
        .map(
            [3][]const u8,
            struct {
                fn splitLine(line: []const u8) [3][]const u8 {
                    var col: [3][]const u8 = undefined;
                    var it = std.mem.tokenizeScalar(u8, line, ',');
                    for (0..3) |i| {
                        col[i] = it.next().?;
                    }

                    return col;
                }
            }.splitLine,
        )
        .peekable();

    try std.testing.expectEqualDeep([3][]const u8{ "a", "b", "c" }, it.peek().?);
    try std.testing.expectEqualDeep([3][]const u8{ "a", "b", "c" }, it.next().?);

    try std.testing.expectEqualDeep([3][]const u8{ "d", "e", "f" }, it.peek().?);
    try std.testing.expectEqualDeep([3][]const u8{ "d", "e", "f" }, it.next().?);

    try std.testing.expectEqual(null, it.peek());
    try std.testing.expectEqual(null, it.next());
}

test "extend map count" {
    var it = extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .map(u8, firstChar);

    try std.testing.expectEqual(3, it.count());
    try std.testing.expectEqual(0, it.count());
}

test "fromSlice map count" {
    var it = fromSlice(&[_][]const u8{ "x", "BB", "ccc" })
        .map(u8, firstChar);

    try std.testing.expectEqual(3, it.count());
    try std.testing.expectEqual(0, it.count());
}

test "extend map" {
    var it = extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .map(u8, firstChar)
        .peekable();

    try std.testing.expectEqual('x', it.peek().?);
    try std.testing.expectEqual('x', it.peek().?);
    try std.testing.expectEqual('x', it.next().?);

    try std.testing.expectEqual('B', it.next().?);
    try std.testing.expectEqual('c', it.next().?);

    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(null, it.peek());
}

test "extend filter" {
    var it = extend(std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' '))
        .filter(isFirstCharUpper);

    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "map-filter-enumerate" {
    var itOrig = extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '));
    try std.testing.expectEqualStrings("x", itOrig.iter.peek().?);
    try std.testing.expectEqualStrings("x", itOrig.next().?);

    var it = extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .enumerate();

    try std.testing.expectEqualDeep(.{ 0, 'x' }, it.next().?);
    try std.testing.expectEqualDeep(.{ 1, 'c' }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "filter and map" {
    var it = extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .filter(isFirstCharUpper)
        .map(u8, firstChar);

    try std.testing.expectEqual('B', it.next().?);
    try std.testing.expectEqual(null, it.next());

    try std.testing.expectEqual(0, it.count());
}

test "two instances from the same Iterator" {
    var it0 = extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' ')).map(u8, firstChar);
    try std.testing.expectEqual('x', it0.next().?);

    var it1 = it0.filter(struct {
        fn isFirstCharUpper(in: u8) bool {
            return std.ascii.isUpper(in);
        }
    }.isFirstCharUpper);

    try std.testing.expectEqual('B', it1.next().?);
    try std.testing.expectEqual(null, it1.next());

    try std.testing.expectEqual(null, it0.next());
}

test "filterMap" {
    var it = extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .filterMap(u8, isFirstCharUpperToChar);

    try std.testing.expectEqual('B', it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "map-fold" {
    const len = extend(std.mem.tokenizeScalar(u8, "xx BB ccc", ' '))
        .map([]const u8, struct {
            fn doNothing(in: []const u8) []const u8 {
                return in;
            }
        }.doNothing)
        .fold(usize, 0, addLen);

    try std.testing.expectEqual(7, len);
}

test "map-stepBy-fold" {
    {
        const len = extend(std.mem.tokenizeScalar(u8, "xx BB ccc", ' '))
            .stepBy(2)
            .map([]const u8, struct {
                fn doNothing(in: []const u8) []const u8 {
                    return in;
                }
            }.doNothing)
            .fold(usize, 0, addLen);

        try std.testing.expectEqual(5, len);
    }

    {
        const len = fromSlice(&[_][]const u8{ "xx", "BB", "ccc" })
            .stepBy(2)
            .map([]const u8, struct {
                fn doNothing(in: []const u8) []const u8 {
                    return in;
                }
            }.doNothing)
            .fold(usize, 0, addLen);

        try std.testing.expectEqual(5, len);
    }
}

test "filter-fold" {
    const len = extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .filter(isFirstCharUpper)
        .fold(usize, 0, addLen);

    try std.testing.expectEqual(2, len);
}

test "filter-stepBy-fold" {
    {
        const len = extend(std.mem.tokenizeScalar(u8, "x BB ccc DD e FFF", ' '))
            .filter(isFirstCharUpper)
            .stepBy(2)
            .fold(usize, 0, addLen);

        try std.testing.expectEqual(5, len);
    }

    {
        const len = fromSlice(&[_][]const u8{ "x", "BB", "ccc", "DD", "e", "FFF" })
            .filter(isFirstCharUpper)
            .stepBy(2)
            .fold(usize, 0, addLen);

        try std.testing.expectEqual(5, len);
    }
    {
        const len = range(u8, 'A', 'D')
            .filter(std.ascii.isUpper)
            .stepBy(2)
            .fold(usize, 0, struct {
            fn add(accum: usize, _: u8) usize {
                return accum + 1;
            }
        }.add);

        try std.testing.expectEqual(2, len);
    }

    {
        const len = extend(std.mem.tokenizeScalar(u8, "BB ccc DD e FFF", ' '))
            .stepBy(2)
            .filter(isFirstCharUpper)
            .fold(usize, 0, addLen);

        try std.testing.expectEqual(7, len);
    }

    {
        const len = fromSlice(&[_][]const u8{ "BB", "ccc", "DD", "e", "FFF" })
            .stepBy(2)
            .filter(isFirstCharUpper)
            .fold(usize, 0, addLen);

        try std.testing.expectEqual(7, len);
    }
}

test "filter-reduce" {
    const sum = struct {
        fn sum(a: i32, b: i32) i32 {
            return a + b;
        }
    }.sum;

    const s1 = fromSlice(&[_]i32{}).reduce(sum);
    try std.testing.expectEqual(null, s1);

    const s2 = fromSlice(&[_]i32{ 1, 3, 5, -1, -3, 7 }).reduce(sum);
    try std.testing.expectEqual(12, s2);

    const s3 = fromSlice("ab").reduce(struct {
        fn sumU8(a: u8, b: u8) u8 {
            return a + b;
        }
    }.sumU8);
    try std.testing.expectEqual(195, s3);
}

test "filter-count" {
    var it1 = extend(std.mem.tokenizeScalar(u8, "x BB ccc D", ' '))
        .filter(isFirstCharUpper);
    try std.testing.expectEqual(2, it1.count());
    try std.testing.expectEqual(0, it1.count());

    var it2 = fromSlice(&[_][]const u8{ "x", "BB", "ccc" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower);

    try std.testing.expectEqual(2, it2.count());
    try std.testing.expectEqual(0, it2.count());
}

test "from slice" {
    var it = fromSlice(&[_][]const u8{ "x", "BB", "ccc" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .enumerate();

    try std.testing.expectEqualDeep(.{ 0, 'x' }, it.next().?);
    try std.testing.expectEqualDeep(.{ 1, 'c' }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "from slice string" {
    var it = fromSlice("xBc")
        .filter(std.ascii.isLower)
        .enumerate();

    try std.testing.expectEqualDeep(.{ 0, 'x' }, it.next().?);
    try std.testing.expectEqualDeep(.{ 1, 'c' }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "from slice with skip" {
    var it = fromSlice(&[_][]const u8{ "x", "BB", "ccc" })
        .skip(1)
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .enumerate();

    try std.testing.expectEqualDeep(.{ 0, 'c' }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "from slice with skip twice" {
    var it = fromSlice(&[_][]const u8{ "x", "BB", "y", "ccc" })
        .skip(1)
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .enumerate()
        .skip(1);

    // { 1, 'c' }, because enumerate was execute ones
    try std.testing.expectEqualDeep(.{ 1, 'c' }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "from slice with skip twice count" {
    var it = fromSlice(&[_][]const u8{ "x", "BB", "y", "ccc" })
        .skip(1)
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .skip(1);

    try std.testing.expectEqual(1, it.count());

    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(0, it.count());
}

test "from slice with skip and count after filter" {
    var it = fromSlice(&[_][]const u8{ "x", "BB", "ccc" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .skip(1);

    //  it.next() => 'c'
    try std.testing.expectEqual(1, it.count());
}

test "from slice with skip count" {
    var it = fromSlice(&[_][]const u8{ "x", "BB", "ccc" })
        .skip(3);

    try std.testing.expectEqual(0, it.count());
}

test "from slice with take" {
    var it = fromSlice(&[_][]const u8{ "x", "BB", "ccc" })
        .take(2)
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .enumerate();

    try std.testing.expectEqualDeep(.{ 0, 'x' }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "from slice try collect" {
    var buffer: [7]u8 = undefined;
    const n = try fromSlice(&[_][]const u8{ "x", "BB", "ccc", "dd", "e", "fff" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .tryCollect(&buffer);

    try std.testing.expectEqual(5, n);
    try std.testing.expectEqualDeep(&[_]u8{ 'x', 'c', 'd', 'e', 'f' }, buffer[0..n]);
}

test "from slice try collect IndexOutOfBound " {
    var buffer: [3]u8 = undefined;
    _ = fromSlice(&[_][]const u8{ "x", "BB", "ccc", "dd", "e", "fff" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .tryCollect(&buffer) catch |err| {
        try std.testing.expectEqual(err, error.IndexOutOfBound);
        return;
    };

    unreachable;
}

test "from slice collect BoundedArray" {
    // TODO: fix this tests for zig version: 0.15
    if (!is_zig_0_14) return error.SkipZigTest;

    var buffer: std.BoundedArray(u8, 7) = try .init(0);

    const n = try fromSlice(&[_][]const u8{ "x", "BB", "ccc", "dd", "e", "fff" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .tryCollectInto(&buffer, std.BoundedArray(u8, 7).append);

    try std.testing.expectEqual(5, n);
    try std.testing.expectEqualDeep(&[_]u8{ 'x', 'c', 'd', 'e', 'f' }, buffer.slice());
}

test "from slice collect ArrayList (alloc)" {
    // TODO: fix this tests for zig version: 0.15
    if (!is_zig_0_14) return error.SkipZigTest;

    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();

    const n = try fromSlice(&[_][]const u8{ "x", "BB", "ccc", "dd", "e", "fff" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .tryCollectInto(&list, std.ArrayList(u8).append);

    try std.testing.expectEqual(5, n);
    try std.testing.expectEqualDeep(&[_]u8{ 'x', 'c', 'd', 'e', 'f' }, list.items[0..n]);
}

test "from slice collect AutoHashMap (alloc)" {
    var map = std.AutoHashMap(usize, u8).init(std.testing.allocator);
    defer map.deinit();

    const put = struct {
        fn put(self: *std.AutoHashMap(usize, u8), item: struct { usize, u8 }) anyerror!void {
            try self.put(item[0], item[1]);
        }
    }.put;

    const n = try fromSlice(&[_][]const u8{ "x", "BB", "ccc", "dd", "e", "fff" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .enumerate()
        .tryCollectInto(&map, put);

    try std.testing.expectEqual(5, n);
    const result = &[_]u8{ 'x', 'c', 'd', 'e', 'f' };
    for (result, 0..) |r, i| {
        try std.testing.expectEqual(r, map.get(i));
    }
}

test "from slice forEach" {
    const forEachFn = struct {
        fn forEach(item: struct { usize, u8 }) void {
            const result = &[_]u8{ 'a', 'c', 'd', 'e', 'f' };
            std.testing.expectEqual(result[item[0]], item[1]) catch unreachable;
        }
    }.forEach;

    fromSlice(&[_][]const u8{ "a", "BB", "ccc", "dd", "e", "fff" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .enumerate()
        .forEach(forEachFn);
}

test "last" {
    var it = extend(std.mem.tokenizeScalar(u8, "a BB ccc dd e fff", ' '))
        .map(u8, firstChar)
        .filter(std.ascii.isLower);

    try std.testing.expectEqual('f', it.last());
    try std.testing.expectEqual(null, it.last());

    const it2 = fromSlice(&[_][]const u8{ "a", "BB", "ccc", "dd", "e", "fff" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower);

    try std.testing.expectEqual('f', it2.last());
    try std.testing.expectEqual(null, it2.last());
}

test "last empty" {
    try std.testing.expectEqual(null, extend(std.mem.tokenizeScalar(u8, "", ' ')).last());
    try std.testing.expectEqual(null, fromSlice(&[_][]const u8{}).last());
}

test "nth" {
    var it = extend(std.mem.tokenizeScalar(u8, "a BB ccc dd e fff", ' '))
        .map(u8, firstChar)
        .filter(std.ascii.isLower);

    try std.testing.expectEqual('e', it.nth(3));
    try std.testing.expectEqual('f', it.nth(0));
    try std.testing.expectEqual(null, it.nth(0));

    const it2 = fromSlice(&[_][]const u8{ "a", "BB", "ccc", "dd", "e", "fff" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower);

    try std.testing.expectEqual('c', it2.nth(1));
    try std.testing.expectEqual('e', it2.nth(1));
    try std.testing.expectEqual(null, it2.nth(1));
}

test "nth empty" {
    try std.testing.expectEqual(null, extend(std.mem.tokenizeScalar(u8, "", ' ')).nth(0));
    try std.testing.expectEqual(null, fromSlice(&[_][]const u8{}).nth(0));
}

test "nth 0" {
    try std.testing.expectEqualStrings("a", extend(std.mem.tokenizeScalar(u8, "a b", ' ')).nth(0).?);
    try std.testing.expectEqualStrings("a", fromSlice(&[_][]const u8{ "a", "b" }).nth(0).?);
}

test "find" {
    var it = extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '));

    const found = it.find(struct {
        fn find(in: []const u8) bool {
            return std.mem.eql(u8, in, "BB");
        }
    }.find);
    try std.testing.expectEqualStrings("BB", found.?);

    // after find, the Iterator works fine, if there are more Items
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "chain" {
    var it = extend(std.mem.tokenizeScalar(u8, "a BB", ' '))
        .chain(std.mem.tokenizeScalar(u8, "ccc DDD", ' '))
        .map(u8, firstChar)
        .filter(std.ascii.isLower);

    try std.testing.expectEqual('a', it.next().?);
    try std.testing.expectEqual('c', it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "chain count" {
    var it = extend(std.mem.tokenizeScalar(u8, "a BB", ' '))
        .chain(std.mem.tokenizeScalar(u8, "ccc DDD", ' '))
        .map(u8, firstChar)
        .filter(std.ascii.isLower);

    try std.testing.expectEqual(2, it.count());
}

test "chain nth" {
    var it = extend(std.mem.tokenizeScalar(u8, "a BB", ' '))
        .chain(std.mem.tokenizeScalar(u8, "ccc DDD", ' '))
        .map(u8, firstChar)
        .filter(std.ascii.isLower);

    try std.testing.expectEqual('c', it.nth(1).?);
}

test "chain 3" {
    var it = extend(std.mem.tokenizeScalar(u8, "a BB", ' '))
        .chain(std.mem.tokenizeScalar(u8, "ccc DDD", ' '))
        .chain(fromSlice(&[_][]const u8{ "e", "F" }));

    try std.testing.expectEqualStrings("a", it.next().?);
    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("ccc", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqualStrings("e", it.next().?);
    try std.testing.expectEqualStrings("F", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "zip char" {
    var it = extend(std.mem.tokenizeScalar(u8, "a BB", ' '))
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .zip(fromSlice(&[_]u8{ 'c', 'D' }));

    try std.testing.expectEqual(.{ 'a', 'c' }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "zip string" {
    var it = extend(std.mem.tokenizeScalar(u8, "a BB", ' '))
        .zip(fromSlice(&[_][]const u8{ "e", "F", "G" }));

    try std.testing.expectEqualDeep(.{ "a", "e" }, it.next().?);
    try std.testing.expectEqualDeep(.{ "BB", "F" }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "zip string count" {
    var it = extend(std.mem.tokenizeScalar(u8, "a BB", ' '))
        .zip(fromSlice(&[_][]const u8{ "e", "F", "G" }));

    try std.testing.expectEqual(2, it.count());
    try std.testing.expectEqual(null, it.next());
}

test "range filter-count" {
    var it1 = range(u8, 'A', 'D').filter(std.ascii.isUpper);
    try std.testing.expectEqual(3, it1.count());
    try std.testing.expectEqual(0, it1.count());

    var it2 = range(f32, 1.1, 5.3);
    try std.testing.expectEqual(5, it2.count());
    try std.testing.expectEqual(0, it2.count());
}

test "range filter-stepBy" {
    var it = range(u8, 'A', 'H')
        .filter(std.ascii.isUpper)
        .stepBy(3);

    try std.testing.expectEqual('A', it.next().?);
    try std.testing.expectEqual('D', it.next().?);
    try std.testing.expectEqual('G', it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "stepBy" {
    var it = extend(std.mem.tokenizeScalar(u8, "a bb CC d e", ' '))
        .stepBy(2)
        .map(u8, firstChar)
        .filter(std.ascii.isLower);

    try std.testing.expectEqual('a', it.next().?);
    try std.testing.expectEqual('e', it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "stepBy nth" {
    var it = extend(std.mem.tokenizeScalar(u8, "a bb CC d e", ' '))
        .stepBy(2)
        .map(u8, firstChar)
        .filter(std.ascii.isLower);

    try std.testing.expectEqual('e', it.nth(1).?);
    try std.testing.expectEqual(null, it.next());
}

pub const IteratorWithError = struct {
    const innerArray = [_]usize{ 2, 3, 4, 5, 6 };
    n: usize = 0,

    pub fn next(self: *@This()) anyerror!?usize {
        if (self.n >= innerArray.len) {
            return null;
        }

        const i = innerArray[self.n];
        self.n += 1;
        if (i % 2 != 0) return error.NotEven;
        return i;
    }
};

test "iterator with error, no error handler" {
    var it = extendWithError(IteratorWithError{}, null);

    try std.testing.expectEqual(2, it.next().?);
    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(null, it.next());
}

pub fn ignoreErrors(_: anyerror) bool {
    return true;
}

test "iterator with error, ignore errors" {
    var it = extendWithError(IteratorWithError{}, ignoreErrors);

    try std.testing.expectEqual(2, it.next().?);
    try std.testing.expectEqual(4, it.next().?);
    try std.testing.expectEqual(6, it.next().?);
    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(null, it.next());
}

test "peekable" {
    var it = extend(std.mem.tokenizeScalar(u8, "a BB ", ' '))
        .map(u8, firstChar)
        .peekable();

    if (it.peek() != 'B') {
        try std.testing.expectEqual('a', it.next().?);
    }

    try std.testing.expectEqual('B', it.peek().?);
    try std.testing.expectEqual('B', it.peek().?);
    try std.testing.expectEqual('B', it.next().?);

    try std.testing.expectEqual(null, it.peek());
    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(null, it.peek());
}

test "peekable filter and map" {
    var it = extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .filter(isFirstCharUpper)
        .map(u8, firstChar)
        .peekable();

    try std.testing.expectEqual('B', it.peek().?);
    try std.testing.expectEqual('B', it.peek().?);
    try std.testing.expectEqual('B', it.next().?);

    try std.testing.expectEqual(null, it.peek());
    try std.testing.expectEqual(null, it.next());
    try std.testing.expectEqual(null, it.peek());
}

test "peekable count" {
    var it = extend(std.mem.tokenizeScalar(u8, "a BB ", ' '))
        .map(u8, firstChar)
        .peekable();

    try std.testing.expectEqual('a', it.peek().?);
    try std.testing.expectEqual(2, it.count());

    it = extend(std.mem.tokenizeScalar(u8, "a BB ", ' '))
        .map(u8, firstChar)
        .peekable();

    try std.testing.expectEqual('a', it.peek().?);
    try std.testing.expectEqual('a', it.next().?);
    try std.testing.expectEqual(1, it.count());
}

const TestIter = struct {
    counter: u8 = 0,

    pub fn next(self: *@This()) ?u8 {
        self.counter += 1;

        if (self.counter > 1) return null;
        return self.counter;
    }

    pub fn nth(_: *@This(), _: usize) ?u8 {
        return 5;
    }

    pub fn count(_: *@This()) usize {
        return 7;
    }
};

test "peekable count one next calls = 2" {
    var it = extend(TestIter{}).peekable();

    try std.testing.expectEqual(1, it.next().?);

    try std.testing.expectEqual(null, it.peek());
    try std.testing.expectEqual(null, it.peek());

    try std.testing.expectEqual(2, it.iter.counter);
}

test "peekable count two next calls = 3" {
    var it = extend(TestIter{}).peekable();

    try std.testing.expectEqual(1, it.next().?);
    try std.testing.expectEqual(null, it.next());

    try std.testing.expectEqual(null, it.peek());
    try std.testing.expectEqual(null, it.peek());

    try std.testing.expectEqual(3, it.iter.counter);
}

test "count No next call" {
    var it = extend(TestIter{});

    try std.testing.expectEqual(7, it.count());
    try std.testing.expectEqual(0, it.iter.counter);
}

test "map count No next call" {
    var it = extend(TestIter{})
        .map(
        u8,
        struct {
            fn map(u: u8) u8 {
                return u;
            }
        }.map,
    );

    try std.testing.expectEqual(7, it.count());
    try std.testing.expectEqual(0, it.iter.iter.counter);
}

test "map-map count No next call" {
    var it = extend(TestIter{})
        .map(u8, struct {
            fn map1(u: u8) u8 {
                return u;
            }
        }.map1)
        .map(
        u8,
        struct {
            fn map2(u: u8) u8 {
                return u;
            }
        }.map2,
    );

    try std.testing.expectEqual(7, it.count());
    try std.testing.expectEqual(0, it.iter.iter.iter.counter);
}

test "map-enumerate count No next call" {
    var it = extend(TestIter{})
        .map(
            u8,
            struct {
                fn map(u: u8) u8 {
                    return u;
                }
            }.map,
        )
        .enumerate();

    try std.testing.expectEqual(7, it.count());
    try std.testing.expectEqual(0, it.iter.iter.iter.counter);
}

test "map-inspect count No next call" {
    var it = extend(TestIter{})
        .map(
            u8,
            struct {
                fn map(u: u8) u8 {
                    return u;
                }
            }.map,
        )
        .inspect(
        struct {
            fn inspect(u: u8) u8 {
                return u;
            }
        }.inspect,
    );

    try std.testing.expectEqual(7, it.count());
    try std.testing.expectEqual(0, it.iter.iter.iter.counter);
}

test "filter-map count next call" {
    var it = extend(TestIter{})
        .filter(struct {
            fn filter(_: u8) bool {
                return true;
            }
        }.filter)
        .map(u8, struct {
        fn map(u: u8) u8 {
            return u;
        }
    }.map);

    try std.testing.expectEqual(1, it.count());
    try std.testing.expectEqual(2, it.iter.iter.iter.counter);
}

test "map-filter count next call" {
    var it = extend(TestIter{})
        .map(u8, struct {
            fn map(u: u8) u8 {
                return u;
            }
        }.map)
        .filter(struct {
        fn filter(_: u8) bool {
            return true;
        }
    }.filter);

    try std.testing.expectEqual(1, it.count());
    try std.testing.expectEqual(2, it.iter.iter.iter.counter);
}

test "peekable nth" {
    {
        var it = extend(TestIter{}).peekable();
        try std.testing.expectEqual(5, it.nth(0).?);
        try std.testing.expectEqual(0, it.iter.counter);
    }

    {
        var it = extend(TestIter{}).peekable();
        try std.testing.expectEqual(1, it.peek().?);
        try std.testing.expectEqual(1, it.nth(0).?);
        try std.testing.expectEqual(1, it.iter.counter);
    }

    {
        var it = extend(TestIter{}).peekable();
        try std.testing.expectEqual(1, it.peek().?);
        try std.testing.expectEqual(5, it.nth(1).?);
        try std.testing.expectEqual(1, it.iter.counter);
    }

    {
        var it = extend(TestIter{}).peekable();
        try std.testing.expectEqual(1, it.next().?);
        try std.testing.expectEqual(null, it.peek());
        try std.testing.expectEqual(null, it.nth(1));
        try std.testing.expectEqual(2, it.iter.counter);
    }
}

test "skip nth" {
    {
        var it = extend(TestIter{}).skip(1);
        try std.testing.expectEqual(5, it.nth(0).?);
        try std.testing.expectEqual(0, it.iter.iter.counter);
    }

    {
        var it = extend(TestIter{}).skip(1);
        try std.testing.expectEqual(5, it.nth(1).?);
        try std.testing.expectEqual(0, it.iter.iter.counter);
    }

    {
        var it = extend(TestIter{}).skip(0);
        try std.testing.expectEqual(1, it.next().?);
        try std.testing.expectEqual(5, it.nth(1));
        try std.testing.expectEqual(1, it.iter.iter.counter);
    }
}

test "stepBy next with nth" {
    {
        var it = extend(TestIter{}).stepBy(0);
        try std.testing.expectEqual(5, it.next().?);
        try std.testing.expectEqual(0, it.iter.iter.counter);
    }

    {
        var it = extend(TestIter{}).stepBy(2);
        try std.testing.expectEqual(5, it.next().?);
        try std.testing.expectEqual(0, it.iter.iter.counter);
    }
}

test "reset extend" {
    var it = extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .map(u8, firstChar);
    try std.testing.expectEqual('x', it.next().?);

    it.reset();
    try std.testing.expectEqual('x', it.next().?);
}

test "reset slice peekable" {
    var it = fromSlice(&[_][]const u8{ "x", "BB", "ccc" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .inspect(
            struct {
                fn inspect(u: u8) u8 {
                    return u;
                }
            }.inspect,
        )
        .enumerate()
        .peekable();

    try std.testing.expectEqual(.{ 0, 'x' }, it.peek().?);
    try std.testing.expectEqual(.{ 0, 'x' }, it.next().?);
    try std.testing.expectEqual(.{ 1, 'c' }, it.peek().?);

    it.reset();
    try std.testing.expectEqual(.{ 0, 'x' }, it.peek().?);
    try std.testing.expectEqual(.{ 0, 'x' }, it.next().?);
}
