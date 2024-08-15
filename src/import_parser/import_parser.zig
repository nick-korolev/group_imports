const std = @import("std");

pub const TokenType = enum {
    Import,
    NamedSpecifierOpen,
    NamedSpecifierClose,
    NamedSpecifier,
    NamedSpecifierLocal,
    Asterisk,
    NamespaceSpecifier,
    DefaultSpecifier,
    From,
    Source,
    AsyncSource,
    As,
};

const ImportType = enum {
    NamedImport,
    NamespaceImport,
    DefaultImport,
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

fn get_token_type(val: []const u8, prev_token: ?*const Token, import_type: ?ImportType) ?TokenType {
    const token_map = std.StaticStringMap(TokenType).initComptime(.{
        .{ "import", .Import },
        .{ "{", .NamedSpecifierOpen },
        .{ "}", .NamedSpecifierClose },
        .{ "*", .Asterisk },
        .{ "as", .As },
        .{ "from", .From },
    });

    if (token_map.get(val)) |token_type| {
        if (prev_token) |ptr| {
            const prev = ptr.*;
            switch (token_type) {
                .NamedSpecifierOpen => return if (prev.token_type == .Import) token_type else null,
                .NamedSpecifierClose => return if (prev.token_type == .NamedSpecifier or prev.token_type == .NamedSpecifierLocal) token_type else null,
                .Asterisk => return if (prev.token_type == .Import) token_type else null,
                .As => return if (prev.token_type == .Asterisk or prev.token_type == .NamedSpecifier or prev.token_type == .NamedSpecifierLocal) token_type else null,
                .From => return switch (prev.token_type) {
                    .NamedSpecifierClose, .DefaultSpecifier, .NamespaceSpecifier => token_type,
                    else => null,
                },
                else => return token_type,
            }
        } else {
            return token_type;
        }
    }

    if (prev_token) |ptr| {
        return switch (ptr.token_type) {
            .NamedSpecifierOpen, .NamedSpecifier, .NamedSpecifierLocal => .NamedSpecifier,
            .As => {
                if (import_type == ImportType.NamedImport) {
                    return TokenType.NamedSpecifierLocal;
                }
                return TokenType.NamespaceSpecifier;
            },
            .From => .Source,
            .Import => {
                if (std.mem.startsWith(u8, val, "'") or std.mem.startsWith(u8, val, "\"")) {
                    return TokenType.Source;
                }
                if (std.mem.startsWith(u8, val, "(") and std.mem.endsWith(u8, val, ")")) {
                    return TokenType.AsyncSource;
                }
                return TokenType.DefaultSpecifier;
            },
            else => null,
        };
    }

    return null;
}

pub fn parse(allocator: std.mem.Allocator, content: *const []const u8) !std.ArrayList(Token) {
    std.debug.print("content: {s}\n", .{content.*});
    var tokens: std.ArrayList(Token) = std.ArrayList(Token).init(allocator);
    var token_iterator = std.mem.tokenizeAny(u8, content.*, " ,;\n");

    var import_type: ?ImportType = null;
    while (token_iterator.next()) |val| {
        // std.debug.print("token: {s}, index: {any}\n", .{ val, token_iterator.index });
        const token_type = if (tokens.items.len > 0)
            get_token_type(val, &tokens.items[tokens.items.len - 1], import_type)
        else
            get_token_type(val, null, import_type);

        if (token_type) |token_type_val| {
            switch (token_type_val) {
                .NamedSpecifierOpen, .NamedSpecifier => import_type = ImportType.NamedImport,
                .Asterisk => import_type = ImportType.NamespaceImport,
                .DefaultSpecifier => import_type = ImportType.DefaultImport,
                else => {},
            }
            try tokens.append(.{ .start = token_iterator.index - val.len, .end = token_iterator.index, .token_type = token_type_val, .raw_value = val });
        }
    }
    return tokens;
}
