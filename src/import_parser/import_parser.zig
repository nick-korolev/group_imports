const std = @import("std");

const TokenType = enum {
    Import,
    SpecifierOpen,
    SpecifierClose,
    Specifier,
    NamespaceSpecifer,
    DefaultSpecifier,
    From,
    Source,
    As,
};

const Token = struct {
    start: usize,
    end: usize,
    token_type: TokenType,
    raw_value: []const u8,

    pub fn format(
        self: Token,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("Token{{ start: {d}, end: {d}, type: {}, value: \"{s}\" }}", .{
            self.start,
            self.end,
            self.token_type,
            self.raw_value,
        });
    }
};

fn get_token_type(val: []const u8, prev_token_ptr: ?*const Token) ?TokenType {
    if (std.mem.eql(u8, val, "import")) {
        return TokenType.Import;
    }

    if (prev_token_ptr) |ptr| {
        const prev_token = ptr.*;
        if (std.mem.eql(u8, val, "{")) {
            if (prev_token.token_type == TokenType.Import) {
                return TokenType.SpecifierOpen;
            }
        }

        if (std.mem.eql(u8, val, "}")) {
            if (prev_token.token_type == TokenType.Specifier) {
                return TokenType.SpecifierClose;
            }
        }

        if (std.mem.eql(u8, val, "as")) {
            if (prev_token.token_type == TokenType.Specifier) {
                return TokenType.As;
            }
        }

        if (std.mem.eql(u8, val, "from")) {
            return switch (prev_token.token_type) {
                TokenType.SpecifierClose, TokenType.DefaultSpecifier, TokenType.NamespaceSpecifer => TokenType.From,
                else => null,
            };
        }
        if (prev_token.token_type == TokenType.SpecifierOpen) {
            return TokenType.Specifier;
        }
        if (prev_token.token_type == TokenType.From) {
            return TokenType.Source;
        }
    }

    return null;
}

pub fn parse(allocator: std.mem.Allocator, content: *const []const u8) !void {
    std.debug.print("content: {s}\n", .{content.*});
    var tokens: std.ArrayList(Token) = std.ArrayList(Token).init(allocator);
    var token_iterator = std.mem.tokenizeAny(u8, content.*, " ");
    var prev_index = token_iterator.index;

    while (token_iterator.next()) |val| {
        // std.debug.print("token: {s}, index: {any}\n", .{ val, token_iterator.index });
        const token_type = if (tokens.items.len > 0)
            get_token_type(val, &tokens.items[tokens.items.len - 1])
        else
            get_token_type(val, null);

        if (token_type) |token_type_val| {
            try tokens.append(.{ .start = prev_index, .end = token_iterator.index, .token_type = token_type_val, .raw_value = val });
        }
        // @TODO implement start
        prev_index = token_iterator.index;
    }

    for (tokens.items) |token| {
        std.debug.print("token: {}\n", .{token});
    }
}
