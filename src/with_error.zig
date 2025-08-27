const std = @import("std");
const Iterator = @import("iter.zig").Iterator;

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
