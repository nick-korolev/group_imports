const std = @import("std");

// generate import tokens
pub fn parse(content: *const []const u8) !void {
    std.debug.print("content: {s}\n", .{content.*});
}
