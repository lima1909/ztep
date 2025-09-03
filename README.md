<div align="center">

# ZTEP 

[![Build Status](https://img.shields.io/github/actions/workflow/status/lima1909/ztep/ci.yaml?style=for-the-badge)](https://github.com/lima1909/ztep/actions)
![License](https://img.shields.io/github/license/lima1909/ztep?style=for-the-badge)
[![Stars](https://img.shields.io/github/stars/lima1909/ztep?style=for-the-badge)](https://github.com/lima1909/ztep/stargazers)

</div>

`ztep` is an extension for Iterators written in ⚡ZIG ⚡.

It is heavily inspired by the iterators in the Rust standard library [std::iter::Iterator](https://doc.rust-lang.org/std/iter/trait.Iterator.html).


#### Supported zig-versions:

- 0.14.1
- 0.15.1

### Examples

#### Extend a zig-std-iterator: `std.mem.TokenIterator`

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

#### Create an Iterator for a given Slice

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

#### Extend a zig-std-iterator: `std.fs.Dir.Walker`, which next-method returns an error_union

```zig
const std = @import("std");
const iter = @import("ztep");

test "iterator with error" {
    const dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
    var walker = try dir.walk(std.testing.allocator);
    defer walker.deinit();

    // errors are ignored and the next Item is yield
    const build = iter.extendWithError(&walker, null).find(struct {
        fn find(entry: std.fs.Dir.Walker.Entry) bool {
            if (std.mem.eql(u8, "build.zig", entry.basename)) return true else return false;
        }
    }.find);

    try std.testing.expectEqualStrings("build.zig", build.?.basename);
}
```


### Iterators

#### Create or extend a Iterator 

| Function          | Description                                                                                      |
|-------------------|--------------------------------------------------------------------------------------------------|
| `empty`           | Creates an iterator that yields nothing.                                                         |
| `extend`          | Extend a given Iterator with the additional methods.                                             |
| `extendWithError` | Extend an Iterator which has a next-method, which returns an error_union (next() anyerror!Item). |
| `fromFn`          | Creates an custom iterator with the initialized (start) value and the provided (next) function.  |
| `fromSlice`       | Create an Iterator from a given slice.                                                           |
| `once`            | Creates an iterator that yields an element exactly once.                                         |
| `range`           | Create an Iterator from a given start and end value (end is excluded).                           |
| `rangeIncl`       | Create an Iterator from a given start and end value (end is inclusive).                          |
| `repeatN`         | Creates a new iterator that N times repeats a given value.                                       |
| `reverse`         | Reverses an iterator’s direction.                                                                |
| `toIterator`      | Creates a Wrapper for a given Iterator, where the next-method has a different name.              |
 

#### The following iterators are available: 

| Iterators        | Description                                                                                            |
|------------------|--------------------------------------------------------------------------------------------------------|
| `chain`          | Takes two iterators and creates a new iterator over both in sequence.                                  |
| `count`          | Consumes the iterator, counting the number of iterations and returning it.                             |
| `enumerate`      | Creates an iterator which gives the current iteration count as well as the next value.                 |
| `filter`         | Creates an iterator which uses a function to determine if an element should be yielded.                |
| `filterMap`      | Creates an iterator that both filters and maps in one call.                                            |
| `find`           | Searches for an element of an iterator that satisfies a predicate.                                     |
| `fold`           | Folds every element into an accumulator by applying an operation, returning the final result.          |
| `forEach`        | Calls a function fn(Item) on each element of an iterator.                                              |
| `inspect`        | This iterator do nothing, the purpose is for debugging.                                                |
| `last`           | Calls a function fn(Item) on each element of an iterator.                                              |
| `map`            | Transforms one iterator into another by a given mapping function.                                      |
| `nth`            | Consumes the iterator, returning the nth element.                                                      |
| `peekable`       | Creates an iterator which can use the peek methods to look at the next element without consuming it.   |
| `reduce`         | Reduces the elements to a single one, by repeatedly applying a reducing function.                      |
| `skip`           | Creates an iterator that skips the first n elements.                                                   |
| `stepBy`         | Creates an iterator starting at the same point, but stepping by the given amount at each iteration.    |
| `take`           | Creates an iterator that yields the first n elements, or fewer if the underlying iterator ends sooner. |
| `tryCollect`     | Collects all the items from an iterator into a given  buffer.                                          |
| `tryCollectInto` | Collects all the items from an iterator into a given collection.                                       |
| `zip`            | Zips up’ two iterators into a single iterator of pairs.                                                |
