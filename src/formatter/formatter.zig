const std = @import("std");
const ImportDeclarationAst = @import("../ast/ast.zig").ImportDeclarationAst;

fn get_pattern(allocator: std.mem.Allocator, import: *const ImportDeclarationAst) ![]const u8 {
    var it = std.mem.splitAny(u8, import.source.raw_value, "/");
    var pattern = std.ArrayList(u8).init(allocator);
    const first = it.next();
    if (first) |first_value| {
        try pattern.appendSlice(first_value);
    }

    const second = it.next();
    if (second) |second_value| {
        try std.fmt.format(pattern.writer(), "/{s}", .{second_value});
    }

    return pattern.items;
}

pub fn format(allocator: std.mem.Allocator, imports: *const std.ArrayList(ImportDeclarationAst)) !void {
    for (imports.items) |import| {
        const pattern = try get_pattern(allocator, &import);
        std.debug.print("pattern: {s}\n", .{pattern});
    }
    try write(allocator, imports);
}

fn write(allocator: std.mem.Allocator, imports: *const std.ArrayList(ImportDeclarationAst)) !void {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    for (imports.*.items) |import| {
        try buffer.appendSlice("import ");
        for (0..import.specifiers.items.len) |idx| {
            const is_last = idx == import.specifiers.items.len - 1;
            const is_first = idx == 0;
            const specifier = import.specifiers.items[idx];
            switch (specifier) {
                .ImportSpecifier => |s| {
                    const separator: []const u8 = if (!is_last) ", " else "";
                    const prefix: []const u8 = if (is_first) "{ " else "";
                    const suffix: []const u8 = if (is_last) " }" else "";
                    const specifier_value = if (std.mem.eql(u8, s.imported.name, s.local.name)) try std.fmt.allocPrint(allocator, "{s}", .{s.imported.name}) else try std.fmt.allocPrint(allocator, "{s} as {s}", .{ s.imported.name, s.local.name });
                    try std.fmt.format(buffer.writer(), "{s}{s}{s}{s}", .{ prefix, specifier_value, separator, suffix });
                },
                .ImportNamespaceSpecifier => |s| try std.fmt.format(buffer.writer(), "* as {s}", .{s.local.name}),
                .ImportDefaultSpecifier => |s| try std.fmt.format(buffer.writer(), "{s}", .{s.local.name}),
            }
        }
        const from = if (import.specifiers.items.len > 0) " from " else "";
        try std.fmt.format(buffer.writer(), "{s}{s} \n", .{ from, import.source.raw_value });
    }
    try std.fs.cwd().writeFile(.{
        .sub_path = "./data/_imports.tsx",
        .data = buffer.items,
    });
}
