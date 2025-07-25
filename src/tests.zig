const std = @import("std");
const from = @import("ztep.zig").from;

fn firstChar(in: []const u8) u8 {
    return in[0];
}

fn isFirstCharUpper(in: []const u8) bool {
    return std.ascii.isUpper(in[0]);
}

fn addLen(accum: usize, in: []const u8) usize {
    return accum + in.len;
}

test "from map" {
    var it = from(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .map(u8, firstChar);

    try std.testing.expectEqual('x', it.next().?);
    try std.testing.expectEqual('B', it.next().?);
    try std.testing.expectEqual('c', it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "from filter" {
    var it = from(std.mem.tokenizeScalar(u8, "a BB ccc DDD", ' '))
        .filter(isFirstCharUpper);

    try std.testing.expectEqualStrings("BB", it.next().?);
    try std.testing.expectEqualStrings("DDD", it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "map-filter-enumerate" {
    var itOrig = from(std.mem.tokenizeScalar(u8, "x BB ccc", ' '));
    try std.testing.expectEqualStrings("x", itOrig.iter().peek().?);
    try std.testing.expectEqualStrings("x", itOrig.next().?);

    var it = from(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .enumerate();

    try std.testing.expectEqualDeep(.{ 0, 'x' }, it.next().?);
    try std.testing.expectEqualDeep(.{ 1, 'c' }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "filter-map" {
    var it = from(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .filter(isFirstCharUpper)
        .map(u8, firstChar);

    try std.testing.expectEqual('B', it.next().?);
    try std.testing.expectEqual(null, it.next());
}

test "filter-fold" {
    const len = from(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .filter(isFirstCharUpper)
        .fold(usize, 0, addLen);

    try std.testing.expectEqual(2, len);
}

test "filter-count" {
    const count = from(std.mem.tokenizeScalar(u8, "x BB ccc D", ' '))
        .filter(isFirstCharUpper)
        .count();

    try std.testing.expectEqual(2, count);
}
