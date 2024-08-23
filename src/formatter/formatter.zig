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
    var patterns = std.BufSet.init(allocator);
    defer patterns.deinit();

    for (imports.items) |import| {
        const pattern = try get_pattern(allocator, &import);
        try patterns.insert(pattern);
    }
    var pattern_array = std.ArrayList([]const u8).init(allocator);
    defer pattern_array.deinit();

    var it = patterns.iterator();
    while (it.next()) |pattern| {
        try pattern_array.append(pattern.*);
    }

    std.mem.sort([]const u8, pattern_array.items, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, b, a);
        }
    }.lessThan);

    try write(allocator, imports, &pattern_array);
}

fn write(allocator: std.mem.Allocator, imports: *const std.ArrayList(ImportDeclarationAst), patterns: *std.ArrayList([]const u8)) !void {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    for (patterns.items) |pattern| {
        std.debug.print("{s}\n", .{pattern});
        for (imports.*.items) |import| {
            const calculated_pattern = try get_pattern(allocator, &import);
            if (std.mem.eql(u8, calculated_pattern, pattern)) {
                try writeLine(allocator, &buffer, &import);
            }
        }
        try buffer.appendSlice("\n");
    }

    try std.fs.cwd().writeFile(.{
        .sub_path = "./data/_imports.tsx",
        .data = buffer.items,
    });
}

fn writeLine(allocator: std.mem.Allocator, buffer: *std.ArrayList(u8), import: *const ImportDeclarationAst) !void {
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
