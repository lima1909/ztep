<div align="center">

# ZTEP 

[![Build Status](https://img.shields.io/github/actions/workflow/status/lima1909/ztep/ci.yaml?style=for-the-badge)](https://github.com/lima1909/ztep/actions)
![License](https://img.shields.io/github/license/lima1909/ztep?style=for-the-badge)
[![Stars](https://img.shields.io/github/stars/lima1909/ztep?style=for-the-badge)](https://github.com/lima1909/ztep/stargazers)

</div>

`ztep` is an extension for Iterators written in ⚡ZIG ⚡.

It is heavily inspired by the iterators in the Rust standard library [std::iter::Iterator](https://doc.rust-lang.org/std/iter/trait.Iterator.html).


```zig
const std = @import("std");
const iter = @import("ztep");

// create a map function, to extract the first char from a string
fn firstChar(in: []const u8) u8 {
    return in[0];
}

// if the Iterator exist, this Iterator can be extended
test "extend" {
    var it = iter.extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .enumerate();

    try std.testing.expectEqualDeep(.{ 0, 'x' }, it.next().?);
    try std.testing.expectEqualDeep(.{ 1, 'c' }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}

// if the Iterator not exist, then can be a Iterator created from a given Slice
test "from slice" {
    var it = iter.fromSlice(&[_][]const u8{ "x", "BB", "ccc" })
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .enumerate();

    try std.testing.expectEqualDeep(.{ 0, 'x' }, it.next().?);
    try std.testing.expectEqualDeep(.{ 1, 'c' }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}
```

### Iterators

Currently, the following iterators are available. More implementations will follow.

| Iterators     | Description                                                                                     |
|---------------|-------------------------------------------------------------------------------------------------|
| `map`         | Transforms one iterator into another by a given mapping function.                               |
| `filter`      | Creates an iterator which uses a function to determine if an element should be yielded.         |
| `enumerate`   | Creates an iterator which gives the current iteration count as well as the next value.          |
| `fold`        | Folds every element into an accumulator by applying an operation, returning the final result.   |
| `count`       | Consumes the iterator, counting the number of iterations and returning it.                      |

