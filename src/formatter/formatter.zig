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
        for (import.specifiers.items) |specifier| {
            switch (specifier) {
                .ImportSpecifier => |s| try std.fmt.format(buffer.writer(), "{{ {s} as {s} }}, ", .{ s.imported.name, s.local.name }),
                .ImportNamespaceSpecifier => |s| try std.fmt.format(buffer.writer(), "* as {s}, ", .{s.local.name}),
                .ImportDefaultSpecifier => |s| try std.fmt.format(buffer.writer(), "{s}, ", .{s.local.name}),
            }
        }
        try std.fmt.format(buffer.writer(), " from {s} \n", .{import.source.raw_value});
    }
    try std.fs.cwd().writeFile(.{
        .sub_path = "./data/_imports.tsx",
        .data = buffer.items,
    });
}
