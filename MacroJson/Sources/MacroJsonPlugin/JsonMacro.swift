import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// This macro will be a peer macro.
/// It doesn't generate code directly for the property it's attached to, but it creates a synthetic member that the @Jsonable macro can later inspect.
public struct JsonMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // This macro wouldn't generate a peer declaration,
        // but rather contribute to the parent struct's Codable conformance.
        return []
    }
}
