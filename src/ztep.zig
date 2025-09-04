const std = @import("std");

pub const Iterator = @import("iter.zig").Iterator;
pub const extend = @import("iter.zig").extend;

pub const fromSlice = @import("producer/slice.zig").fromSlice;
pub const range = @import("producer/range.zig").range;
pub const rangeIncl = @import("producer/range.zig").rangeIncl;
pub const fromFn = @import("producer/fromfn.zig").fromFn;
pub const empty = @import("producer/repeatn.zig").empty;
pub const once = @import("producer/repeatn.zig").once;
pub const repeatN = @import("producer/repeatn.zig").repeatN;
pub const extendWithError = @import("producer/with_error.zig").extendWithError;
pub const toIterator = @import("producer/to_iter.zig").toIterator;
pub const reverse = @import("producer/to_iter.zig").reverse;

test {
    _ = @import("./tests.zig");

    std.testing.refAllDeclsRecursive(@This());
}
