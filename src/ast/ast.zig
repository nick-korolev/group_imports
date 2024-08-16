const std = @import("std");
const import_parser = @import("../import_parser/import_parser.zig");

const IdentifierStruct = struct { type: []const u8 = "Identifier", start: usize, end: usize, name: []const u8 };

const ImportSpecifierStruct = struct {
    type: []const u8 = "ImportSpecifier",
    start: usize,
    end: usize,
    imported: IdentifierStruct,
    local: IdentifierStruct,
};

const ImportNamespaceSpecifierStruct = struct {
    type: []const u8 = "ImportNamespaceSpecifier",
    start: usize,
    end: usize,
    local: IdentifierStruct,
};

const ImportDefaultSpecifierStruct = struct {
    type: []const u8 = "ImportDefaultSpecifier",
    start: usize,
    end: usize,
    local: IdentifierStruct,
};

const SpecifierUnionStruct = union(enum) {
    ImportSpecifier: ImportSpecifierStruct,
    ImportNamespaceSpecifier: ImportNamespaceSpecifierStruct,
    ImportDefaultSpecifier: ImportDefaultSpecifierStruct,
};

const SourceStruct = struct {
    type: []const u8 = "Literal",
    start: usize,
    end: usize,
    value: []const u8,
    raw_value: []const u8,
};

pub const ImportDeclarationAst = struct {
    type: []const u8 = "ImportDeclaration",
    start: usize,
    end: usize,
    specifiers: std.ArrayList(SpecifierUnionStruct),
    source: SourceStruct,
};

pub fn build(allocator: std.mem.Allocator, tokens: *const std.ArrayList(import_parser.Token)) !std.ArrayList(ImportDeclarationAst) {
    var imports = std.ArrayList(ImportDeclarationAst).init(allocator);

    var current_import_declaration_ast = ImportDeclarationAst{
        .start = 0,
        .end = 0,
        .specifiers = std.ArrayList(SpecifierUnionStruct).init(allocator),
        .source = SourceStruct{
            .start = 0,
            .end = 0,
            .raw_value = "",
            .value = "",
        },
    };
    for (0..tokens.*.items.len) |idx| {
        const token = tokens.*.items[idx];
        std.debug.print("{}\n", .{token});
        if (token.token_type == import_parser.TokenType.Import) {
            current_import_declaration_ast.start = token.start;
            current_import_declaration_ast.end = token.end;
        }

        if (token.token_type == import_parser.TokenType.NamedSpecifier or token.token_type == import_parser.TokenType.NamespaceSpecifier or token.token_type == import_parser.TokenType.DefaultSpecifier) {
            switch (token.token_type) {
                .NamedSpecifier => {
                    const next_token: ?import_parser.Token = if ((idx + 1) < tokens.*.items.len) tokens.*.items[idx + 1] else null;
                    var local_token = token;
                    if (next_token.?.token_type == import_parser.TokenType.As and (idx + 2) < tokens.*.items.len) {
                        local_token = tokens.*.items[idx + 2];
                    }
                    try current_import_declaration_ast.specifiers.append(SpecifierUnionStruct{
                        .ImportSpecifier = ImportSpecifierStruct{
                            .start = token.start,
                            .end = token.end,
                            .imported = IdentifierStruct{
                                .start = token.start,
                                .end = token.end,
                                .name = token.raw_value,
                            },
                            .local = IdentifierStruct{
                                .start = local_token.start,
                                .end = local_token.end,
                                .name = local_token.raw_value,
                            },
                        },
                    });
                },
                .NamespaceSpecifier => try current_import_declaration_ast.specifiers.append(SpecifierUnionStruct{
                    .ImportNamespaceSpecifier = ImportNamespaceSpecifierStruct{ .start = token.start, .end = token.end, .local = IdentifierStruct{
                        .start = token.start,
                        .end = token.end,
                        .name = token.raw_value,
                    } },
                }),
                .DefaultSpecifier => try current_import_declaration_ast.specifiers.append(SpecifierUnionStruct{
                    .ImportDefaultSpecifier = ImportDefaultSpecifierStruct{ .start = token.start, .end = token.end, .local = IdentifierStruct{
                        .start = token.start,
                        .end = token.end,
                        .name = token.raw_value,
                    } },
                }),
                else => {
                    std.debug.print("Unknown Specifier {s}", .{token.raw_value});
                },
            }
        }

        if (token.token_type == import_parser.TokenType.Source) {
            current_import_declaration_ast.source.start = token.start;
            current_import_declaration_ast.source.end = token.end;
            current_import_declaration_ast.source.raw_value = token.raw_value;
            current_import_declaration_ast.source.value = token.raw_value;

            try imports.append(current_import_declaration_ast);

            current_import_declaration_ast = ImportDeclarationAst{
                .start = 0,
                .end = 0,
                .specifiers = std.ArrayList(SpecifierUnionStruct).init(allocator),
                .source = SourceStruct{
                    .start = 0,
                    .end = 0,
                    .raw_value = "",
                    .value = "",
                },
            };
        }
    }

    return imports;
}
