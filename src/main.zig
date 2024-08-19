const std = @import("std");
const import_parser = @import("./import_parser/import_parser.zig");
const file_reader = @import("./file_reader/file_reader.zig");
const ast = @import("./ast/ast.zig");
const formatter = @import("./formatter/formatter.zig");

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

    try formatter.format(arena_allocator, &imports);
}
