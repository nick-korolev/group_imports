const std = @import("std");
const import_parser = @import("./import_parser/import_parser.zig");

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

    const str: []const u8 = "import { App }  from './route' ";
    try import_parser.parse(arena_allocator, &str);
}
