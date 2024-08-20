const std = @import("std");
const ImportDeclarationAst = @import("../ast/ast.zig").ImportDeclarationAst;

fn getFirstPattern(source: []const u8) []const u8 {
    if (std.mem.indexOf(u8, source, "/")) |slash_index| {
        return source[0 .. slash_index + 1];
    }
    return source;
}

fn compare(context: void, a: ImportDeclarationAst, b: ImportDeclarationAst) bool {
    _ = context;
    const pattern_a = getFirstPattern(a.source.value);
    const pattern_b = getFirstPattern(b.source.value);

    if (std.mem.eql(u8, pattern_a, pattern_b)) {
        return std.mem.lessThan(u8, b.source.value, a.source.value);
    }

    return std.mem.lessThan(u8, pattern_b, pattern_a);
}

pub fn format(allocator: std.mem.Allocator, imports: *const std.ArrayList(ImportDeclarationAst)) !void {
    std.mem.sort(ImportDeclarationAst, imports.*.items, {}, compare);
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
