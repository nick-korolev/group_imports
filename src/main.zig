const std = @import("std");
const import_parser = @import("./import_parser/import_parser.zig");
const file_reader = @import("./file_reader/file_reader.zig");
const ast = @import("./ast/ast.zig");

pub fn main() !void {
    const start_time = std.time.milliTimestamp();
    defer {
        const end_time = std.time.milliTimestamp();

        const duration = end_time - start_time;
        std.debug.print("Done: {} ms\n", .{duration});
        std.debug.print("=================================================\n", .{});
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    defer {
        const leaked = gpa.deinit();
        switch (leaked) {
            .leak => std.debug.print("Leaked", .{}),
            .ok => {},
        }
    }

    const allocator = gpa.allocator();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const file = try file_reader.read_file(arena_allocator, "./data/imports.tsx");
    const tokens = try import_parser.parse(arena_allocator, &file);
    defer tokens.deinit();

    const imports = try ast.build(arena_allocator, &tokens);
    defer imports.deinit();

    for (imports.items) |import| {
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
