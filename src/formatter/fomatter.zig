const std = @import("std");
const ImportDeclarationAst = @import("../ast/ast.zig").ImportDeclarationAst;

fn compare(context: void, a: ImportDeclarationAst, b: ImportDeclarationAst) bool {
    _ = context;
    return a.source.value.len > b.source.value.len;
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
