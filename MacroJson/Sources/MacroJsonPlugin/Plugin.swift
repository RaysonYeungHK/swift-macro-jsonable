import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// Export Macros to other packages
@main
struct JsonPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        JsonMacro.self,
        JsonableMacro.self,
    ]
}
