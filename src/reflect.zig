const std = @import("std");
const comptimePrint=std.fmt.comptimePrint;

/// generate a tuple through a fn param slice
/// Tuple keeps the same order as sliced
pub fn fnParamsToTuple(comptime params: []const std.builtin.Type.Fn.Param) type {
    const Type = std.builtin.Type;
    const fields: [params.len]Type.StructField = blk: {
        var res: [params.len]Type.StructField = undefined;

        for (params, 0..params.len) |param, i| {
            res[i] = Type.StructField{
                .type = param.type.?,
                .alignment = @alignOf(param.type.?),
                .default_value = null,
                .is_comptime = false,
                .name = std.fmt.comptimePrint("{}", .{i}),
            };
        }
        break :blk res;
    };
    return @Type(.{
        .Struct = std.builtin.Type.Struct{
            .layout = .Auto,
            .is_tuple = true,
            .decls = &.{},
            .fields = &fields,
        },
    });
}

pub fn typeIfNeedAlloc(comptime T: type) bool {
    const type_info = @typeInfo(T);
    switch (type_info) {
        .Void => {
            return false;
        },
        .Optional => |optional| {
            return typeIfNeedAlloc(optional.child);
        },
        .Null => {
            return false;
        },
        .Bool => {
            return false;
        },
        .Int => {
            return false;
        },
        .Float => {
            return false;
        },
        .Enum => {
            return false;
        },
        .Array => |array| {
            return typeIfNeedAlloc(array.child);
        },
        .Union => |u| {
            inline for (u.fields) |field| {
                if (typeIfNeedAlloc(field.type)) {
                    return true;
                }
            }
            return false;
        },
        .Struct => |s| {
            if (s.is_tuple) {
                inline for (s.fields) |field| {
                    if (typeIfNeedAlloc(field.type)) {
                        return true;
                    }
                }
                return false;
            } else {
                return true;
            }
        },
        .Pointer => {
            return true;
        },
        else => {
            const err_msg = comptimePrint("this type ({}) is not supported!", .{T});
            @compileError(err_msg);
        },
    }

    return true;
}
