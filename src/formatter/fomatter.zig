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
        return std.mem.lessThan(u8, a.source.value, b.source.value);
    }

    return std.mem.lessThan(u8, pattern_a, pattern_b);
}

pub fn format(imports: *const std.ArrayList(ImportDeclarationAst)) !void {
    std.mem.sort(ImportDeclarationAst, imports.*.items, {}, compare);
    for (imports.*.items) |import| {
        std.debug.print("import {s} start: {any} end: {any} from : {s} \n", .{ import.type, import.start, import.end, import.source.raw_value });
        std.debug.print("  Specifiers:\n", .{});

        for (import.specifiers.items) |specifier| {
            switch (specifier) {
                .ImportSpecifier => |s| std.debug.print("    ImportSpecifier: imported={s}, local={s}\n", .{ s.imported.name, s.local.name }),
                .ImportNamespaceSpecifier => |s| std.debug.print("    ImportNamespaceSpecifier: local={s}\n", .{s.local.name}),
                .ImportDefaultSpecifier => |s| std.debug.print("    ImportDefaultSpecifier: local={s}\n", .{s.local.name}),
            }
        }
    }
}
