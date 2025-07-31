<div align="center">

# ZTEP 

[![Build Status](https://img.shields.io/github/actions/workflow/status/lima1909/ztep/ci.yaml?style=for-the-badge)](https://github.com/lima1909/ztep/actions)
![License](https://img.shields.io/github/license/lima1909/ztep?style=for-the-badge)
[![Stars](https://img.shields.io/github/stars/lima1909/ztep?style=for-the-badge)](https://github.com/lima1909/ztep/stargazers)

</div>

`ztep` is an extension for Iterators written in ⚡ZIG ⚡.

It is heavily inspired by the iterators in the Rust standard library [std::iter::Iterator](https://doc.rust-lang.org/std/iter/trait.Iterator.html).

## Examples

### Extend a zig-std-iterator: `std.mem.TokenIterator`

```zig
const std = @import("std");
const iter = @import("ztep");

fn firstChar(in: []const u8) u8 {
    return in[0];
}

test "extend" {
    var it = iter.extend(std.mem.tokenizeScalar(u8, "x BB ccc", ' '))
        .map(u8, firstChar)
        .filter(std.ascii.isLower)
        .enumerate();

    try std.testing.expectEqualDeep(.{ 0, 'x' }, it.next().?);
    try std.testing.expectEqualDeep(.{ 1, 'c' }, it.next().?);
    try std.testing.expectEqual(null, it.next());
}
```

### Create an Iterator for a given Slice

```zig
const std = @import("std");
const iter = @import("ztep");

fn firstChar(in: []const u8) u8 {
    return in[0];
}

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


## Iterators

Currently, the following iterators are available. More implementations will follow.

| Iterators        | Description                                                                                            |
|------------------|--------------------------------------------------------------------------------------------------------|
| `map`            | Transforms one iterator into another by a given mapping function.                                      |
| `filter`         | Creates an iterator which uses a function to determine if an element should be yielded.                |
| `filterMap`      | Creates an iterator that both filters and maps in one call.                                            |
| `enumerate`      | Creates an iterator which gives the current iteration count as well as the next value.                 |
| `fold`           | Folds every element into an accumulator by applying an operation, returning the final result.          |
| `skip`           | Creates an iterator that skips the first n elements.                                                   |
| `take`           | Creates an iterator that yields the first n elements, or fewer if the underlying iterator ends sooner. |
| `inspect`        | This iterator do nothing, the purpose is for debugging.                                                |
| `count`          | Consumes the iterator, counting the number of iterations and returning it.                             |
| `last`           | Calls a function fn(Item) on each element of an iterator.                                              |
| `nth`            | Consumes the iterator, returning the nth element.                                                      |
| `forEach`        | Calls a function fn(Item) on each element of an iterator.                                              |
| `tryCollect`     | Collects all the items from an iterator into a given  buffer.                                          |
| `tryCollectInto` | Collects all the items from an iterator into a given collection.                                       |
