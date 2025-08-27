const std = @import("std");

pub const Iterator = @import("iter.zig").Iterator;

pub const extend = @import("iter.zig").extend;
pub const fromSlice = @import("slice.zig").fromSlice;
pub const range = @import("range.zig").range;
pub const rangeIncl = @import("range.zig").rangeIncl;
pub const fromFn = @import("fromfn.zig").fromFn;
pub const empty = @import("repeatn.zig").empty;
pub const once = @import("repeatn.zig").once;
pub const repeatN = @import("repeatn.zig").repeatN;
pub const extendWithError = @import("with_error.zig").extendWithError;
pub const toIterator = @import("to_iter.zig").toIterator;
pub const reverse = @import("to_iter.zig").reverse;

test {
    _ = @import("./tests.zig");

    _ = @import("chain.zig");
    _ = @import("enumerate.zig");
    _ = @import("filter.zig");
    _ = @import("filter_map.zig");
    _ = @import("inspect.zig");
    _ = @import("map.zig");
    _ = @import("peekable.zig");
    _ = @import("skip.zig");
    _ = @import("stepby.zig");
    _ = @import("take.zig");
    _ = @import("zip.zig");

    _ = @import("fromfn.zig");
    _ = @import("iter.zig");
    _ = @import("range.zig");
    _ = @import("repeatn.zig");
    _ = @import("slice.zig");
    _ = @import("to_iter.zig");
    _ = @import("with_error.zig");
}
