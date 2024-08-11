const std = @import("std");
const fs = std.fs;

pub fn read_file(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = try fs.cwd().openFile(path, .{ .mode = .read_write });
    defer file.close();

    const file_size = try file.getEndPos();

    const buffer = try allocator.alloc(u8, file_size);

    _ = try file.readAll(buffer);

    return buffer;
}
