const std = @import("std");
const extend = @import("ztep.zig").extend;
const fromSlice = @import("ztep.zig").fromSlice;

fn firstChar(in: []const u8) u8 {
    return in[0];
}

fn isFirstCharUpper(in: []const u8) bool {
    return std.ascii.isUpper(in[0]);
}

fn addLen(accum: usize, in: []const u8) usize {
    return accum + in.len;
}

test "extend map" {
    var it = extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .map(u8, firstChar);

    try std.testing.expectEqual('x', it.next().?);
    try std.testing.expectEqual('B', it.next().?);
    try std.testing.expectEqual('c', it.next().?);
    try std.testing.expectEqual(null, it.next());
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

test "filter-map" {
    var it = extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .filter(isFirstCharUpper)
        .map(u8, firstChar);

    try std.testing.expectEqual('B', it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "filter-fold" {
    const len = extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .filter(isFirstCharUpper)
        .fold(usize, 0, addLen);

    try std.testing.expectEqual(2, len);
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
    var buffer: std.BoundedArray(u8, 7) = try .init(0);

    const n = try fromSlice(&[_][]const u8{ "x", "BB", "ccc", "dd", "e", "fff" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .tryCollectInto(&buffer, std.BoundedArray(u8, 7).append);

    try std.testing.expectEqual(5, n);
    try std.testing.expectEqualDeep(&[_]u8{ 'x', 'c', 'd', 'e', 'f' }, buffer.slice());
}

test "from slice collect ArrayList (alloc)" {
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

test "from slice for_each" {
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
        .for_each(forEachFn);
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

    try std.testing.expectEqual(null, it2.nth(5));
}

test "nth empty" {
    try std.testing.expectEqual(null, extend(std.mem.tokenizeScalar(u8, "", ' ')).nth(0));
    try std.testing.expectEqual(null, fromSlice(&[_][]const u8{}).nth(0));
}
