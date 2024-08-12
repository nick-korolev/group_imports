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
    ImportDefauleSpecifier: ImportDefaultSpecifierStruct,
};

const SourceStruct = struct {
    type: []const u8 = "Literal",
    start: usize,
    end: usize,
    value: []const u8,
    raw_value: []const u8,
};

const ImportDeclarationAst = struct {
    type: []const u8 = "ImportDeclaration",
    start: usize,
    end: usize,
    specifiers: std.ArrayList(SpecifierUnionStruct),
    source: SourceStruct,
};

pub fn build(allocator: std.mem.Allocator, tokens: *const std.ArrayList(import_parser.Token)) !void {
    var specifiers = std.ArrayList(SpecifierUnionStruct).init(allocator);
    const testSpecifier = SpecifierUnionStruct{ .ImportSpecifier = ImportSpecifierStruct{ .start = 0, .end = 1, .imported = IdentifierStruct{
        .start = 0,
        .end = 1,
        .name = "Test",
    }, .local = IdentifierStruct{
        .start = 0,
        .end = 1,
        .name = "Test",
    } } };
    try specifiers.append(testSpecifier);
    const source = SourceStruct{
        .start = 0,
        .end = 1,
        .raw_value = "'./test'",
        .value = "./test",
    };
    const import_declaration = ImportDeclarationAst{ .start = 0, .end = 1, .specifiers = specifiers, .source = source };

    std.debug.print("{}\n", .{tokens.items.len});

    std.debug.print("{}\n", .{import_declaration});
}
