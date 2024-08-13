const std = @import("std");

pub const TokenType = enum {
    Import,
    NamedSpecifierOpen,
    NamedSpecifierClose,
    NamedSpecifier,
    Asterisk,
    NamespaceSpecifier,
    DefaultSpecifier,
    From,
    Source,
    As,
};

pub const Token = struct {
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
// @todo refactor
fn get_token_type(val: []const u8, prev_token_ptr: ?*const Token) ?TokenType {
    if (std.mem.eql(u8, val, "import")) {
        return TokenType.Import;
    }

    if (prev_token_ptr) |ptr| {
        const prev_token = ptr.*;
        if (std.mem.eql(u8, val, "{")) {
            if (prev_token.token_type == TokenType.Import) {
                return TokenType.NamedSpecifierOpen;
            }
        }

        if (std.mem.eql(u8, val, "}")) {
            if (prev_token.token_type == TokenType.NamedSpecifier) {
                return TokenType.NamedSpecifierClose;
            }
        }

        if (std.mem.eql(u8, val, "*")) {
            if (prev_token.token_type == TokenType.Import) {
                return TokenType.Asterisk;
            }
        }

        if (std.mem.eql(u8, val, "as")) {
            if (prev_token.token_type == TokenType.Asterisk) {
                return TokenType.As;
            }
        }

        if (std.mem.eql(u8, val, "from")) {
            return switch (prev_token.token_type) {
                TokenType.NamedSpecifierClose, TokenType.DefaultSpecifier, TokenType.NamespaceSpecifier => TokenType.From,
                else => null,
            };
        }

        if (prev_token.token_type == TokenType.NamedSpecifierOpen) {
            return TokenType.NamedSpecifier;
        }

        if (prev_token.token_type == TokenType.NamedSpecifier) {
            return TokenType.NamedSpecifier;
        }

        if (prev_token.token_type == TokenType.As) {
            return TokenType.NamespaceSpecifier;
        }

        if (prev_token.token_type == TokenType.From) {
            return TokenType.Source;
        }

        if (prev_token.token_type == TokenType.Import) {
            return TokenType.DefaultSpecifier;
        }
    }

    return null;
}

pub fn parse(allocator: std.mem.Allocator, content: *const []const u8) !std.ArrayList(Token) {
    std.debug.print("content: {s}\n", .{content.*});
    var tokens: std.ArrayList(Token) = std.ArrayList(Token).init(allocator);
    var token_iterator = std.mem.tokenizeAny(u8, content.*, " ,;\n");

    while (token_iterator.next()) |val| {
        // std.debug.print("token: {s}, index: {any}\n", .{ val, token_iterator.index });
        const token_type = if (tokens.items.len > 0)
            get_token_type(val, &tokens.items[tokens.items.len - 1])
        else
            get_token_type(val, null);

        if (token_type) |token_type_val| {
            try tokens.append(.{ .start = token_iterator.index - val.len, .end = token_iterator.index, .token_type = token_type_val, .raw_value = val });
        }
    }
    return tokens;
}
