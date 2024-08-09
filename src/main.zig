const std = @import("std");
const import_parser = @import("./import_parser/import_parser.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        switch (leaked) {
            .leak => std.debug.print("Leaked", .{}),
            .ok => {},
        }
    }

    const str: []const u8 = "import { App } from './route' ";
    try import_parser.parse(&str);
}
