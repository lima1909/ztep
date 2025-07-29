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
    try std.testing.expectEqualStrings("x", itOrig.iter().peek().?);
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
    const count = extend(std.mem.tokenizeScalar(u8, "x BB ccc D", ' '))
        .filter(isFirstCharUpper)
        .count();

    try std.testing.expectEqual(2, count);
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

test "from slice collect" {
    var collector = fromSlice(&[_][]const u8{ "x", "BB", "ccc", "dd", "e", "fff" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .collect();

    const result = &[_]u8{ 'x', 'c', 'd', 'e', 'f' };
    var i: usize = 0;
    var buffer: [1]u8 = undefined;
    while (collector.collect(&buffer)) |n| {
        try std.testing.expectEqual(1, n);
        try std.testing.expectEqual(result[i], buffer[0]);
        i += 1;
    }
}

test "from slice collect once" {
    var collector = fromSlice(&[_][]const u8{ "x", "BB", "ccc", "dd", "e", "fff" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .collect();

    var buffer: [7]u8 = undefined;
    const n = collector.collect(&buffer) orelse 0;
    try std.testing.expectEqualDeep(&[_]u8{ 'x', 'c', 'd', 'e', 'f' }, buffer[0..n]);
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
