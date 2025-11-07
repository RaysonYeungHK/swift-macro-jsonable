import SwiftCompilerPlugin
import SwiftSyntaxMacros

@attached(peer, names: arbitrary)
public macro Json(name: String) = #externalMacro(module: "MacroJsonPlugin", type: "JsonMacro")

@attached(member, names: arbitrary)
public macro Jsonable() = #externalMacro(module: "MacroJsonPlugin", type: "JsonableMacro")
