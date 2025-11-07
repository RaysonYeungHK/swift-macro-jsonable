import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// `@Jsonable` is a member macro that generates Codable conformance for a struct or class.
/// It inspects properties for `@Json(name: "...")` to create custom CodingKeys.
public struct JsonableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let isClass: Bool
        let typeName: String

        if let structDecl = declaration.as(StructDeclSyntax.self) {
            isClass = false
            typeName = structDecl.name.text
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            isClass = true
            typeName = classDecl.name.text
        } else {
            throw CustomMacroError.notAClassOrStruct
        }

        var initParameters: [String] = []
        var initStatements: [String] = []
        var codingKeysCases: [String] = []
        var decodeStatements: [String] = []
        var encodeStatements: [String] = []

        // Iterate over the members (properties) of the struct/class
        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
            guard let binding = varDecl.bindings.first else { continue }
            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { continue }

            // Skip static properties and computed properties for Codable generation
            if varDecl.modifiers.contains(where: { $0.name.text == "static" }) { continue }
            if binding.accessorBlock != nil { continue } // Skip computed properties

            // Extract the type annotation (e.g., "String?", "Int", "User")
            let rawTypeAnnotation = binding.typeAnnotation?.type.description ?? "Any"
            let typeAnnotation: String = if let indexOfComment = rawTypeAnnotation.firstIndex(of: "/") {
                String(rawTypeAnnotation.prefix(upTo: indexOfComment)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                rawTypeAnnotation.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let isOptional = typeAnnotation.hasSuffix("?") // Simple check for optionality

            // Check for @Json(name: "...") attribute
            var jsonKey: String?
            if let jsonAttribute = varDecl.attributes.first(where: { attr in
                attr.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Json"
            }),
               let jsonAttr = jsonAttribute.as(AttributeSyntax.self),
               let arguments = jsonAttr.arguments?.as(LabeledExprListSyntax.self),
               let nameArg = arguments.first(where: { $0.label?.text == "name" }),
               let stringLiteral = nameArg.expression.as(StringLiteralExprSyntax.self),
               let firstSegment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                jsonKey = firstSegment.content.text
            }
            
            // --- Generate init parameters ---
            initParameters.append("\(identifier): \(typeAnnotation)")
            
            // --- Generate init Statement ---
            initStatements.append("self.\(identifier) = \(identifier)")

            // --- Generate CodingKeys case ---
            if let key = jsonKey {
                codingKeysCases.append("case \(identifier) = \"\(key)\"")
            } else {
                codingKeysCases.append("case \(identifier)")
            }

            // --- Generate Decode Statement ---
            let decodeMethod = isOptional ? "decodeIfPresent" : "decode"
            let decodeType = isOptional ? String(typeAnnotation.dropLast()) : typeAnnotation // Remove "?" for type
            decodeStatements.append(
                "self.\(identifier) = try container.\(decodeMethod)(\(decodeType).self, forKey: .\(identifier))"
            )

            // --- Generate Encode Statement ---
            let encodeMethod = isOptional ? "encodeIfPresent" : "encode"
            encodeStatements.append(
                "try container.\(encodeMethod)(self.\(identifier), forKey: .\(identifier))"
            )
        }
        
        // MARK: - Generate init
        let initFunc =
        """
        init(\(initParameters.joined(separator: ", "))) {
            \(initStatements.joined(separator: "\n        "))
        }
        """

        // MARK: - Generate CodingKeys enum

        let codingKeysEnum =
        """
        private enum CodingKeys: String, CodingKey {
            \(codingKeysCases.joined(separator: "\n        "))
        }
        """

        // MARK: - Generate init(from: Decoder)

        let initDecoder: String
        if isClass {
            // For classes, init(from:) must be 'required' and call super.init()
            // This simplified version assumes no custom designated initializers
            // or a superclass that doesn't need init(from:) or handles it.
            // If the class has a superclass that also conforms to Codable,
            // 'try super.init(from: decoder)' would be needed *before* property assignments.
            // For this example, we assume a base class or one not needing super.init(from:).
            // This is a simplification; complex class hierarchies require more advanced macro logic.
            initDecoder =
            """
            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                \(decodeStatements.joined(separator: "\n                "))
                // If \(typeName) inherits from a Codable superclass,
                // 'try super.init(from: decoder)' would be needed here *before* assignments.
            }
            """
        } else { // Struct
            initDecoder =
            """
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                \(decodeStatements.joined(separator: "\n            "))
            }
            """
        }


        // MARK: - Generate encode(to: Encoder)

        let encodeEncoder =
        """
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            \(encodeStatements.joined(separator: "\n            "))
        }
        """

        // Return the generated declarations
        return [
            DeclSyntax(stringLiteral: initFunc),
            DeclSyntax(stringLiteral: codingKeysEnum),
            DeclSyntax(stringLiteral: initDecoder),
            DeclSyntax(stringLiteral: encodeEncoder)
        ]
    }
}

public enum CustomMacroError: Error, CustomStringConvertible {
    case notAClassOrStruct
    case invalidJsonAttribute

    public var description: String {
        switch self {
            case .notAClassOrStruct: "The @Jsonable macro can only be applied to a class or a struct."
            case .invalidJsonAttribute: "Invalid @Json attribute usage."
        }
    }
}
