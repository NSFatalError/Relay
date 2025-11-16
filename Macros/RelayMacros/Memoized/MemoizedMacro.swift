//
//  MemoizedMacro.swift
//  Relay
//
//  Created by Kamil Strzelecki on 14/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

public enum MemoizedMacro {

    private struct Input {

        let declaration: FunctionDeclSyntax
        let trimmedReturnType: TypeSyntax
        let propertyName: String
    }

    private static func validate(
        _ declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext,
        with parameters: Parameters
    ) -> Input? {
        guard let declaration = declaration.as(FunctionDeclSyntax.self),
              let trimmedReturnType = trimmedReturnType(of: declaration),
              declaration.signature.parameterClause.parameters.isEmpty,
              declaration.signature.effectSpecifiers == nil,
              declaration.typeScopeSpecifier == nil
        else {
            context.diagnose(
                node: declaration,
                errorMessage: """
                Memoized macro can only be applied to non-void, non-async, non-throwing \
                methods that don't take any arguments
                """
            )
            return nil
        }

        guard let scope = context.lexicalContext.first?.as(ClassDeclSyntax.self),
              scope.attributes.contains(likeOneOf: "@Observable", "@Model")
        else {
            context.diagnose(
                node: declaration,
                errorMessage: """
                Memoized macro can only be applied to methods declared in body (not extension) \
                of @Observable or @Model classes
                """
            )
            return nil
        }

        let propertyName = validatePropertyName(
            for: declaration,
            in: context,
            preferred: parameters.preferredPropertyName
        )

        guard let propertyName else {
            return nil
        }

        return Input(
            declaration: declaration,
            trimmedReturnType: trimmedReturnType,
            propertyName: propertyName
        )
    }

    private static func validatePropertyName(
        for declaration: FunctionDeclSyntax,
        in context: some MacroExpansionContext,
        preferred: String?
    ) -> String? {
        if let preferred {
            guard !preferred.isEmpty else {
                context.diagnose(
                    node: declaration,
                    errorMessage: "Memoized macro requires a non-empty property name"
                )
                return nil
            }
            return preferred
        }

        let inferred = defaultPropertyName(for: declaration)
        guard !inferred.isEmpty else {
            context.diagnose(
                node: declaration,
                errorMessage: """
                Memoized macro requires a method name with at least two words \
                or explicit property name
                """
            )
            return nil
        }

        return inferred
    }

    static func defaultPropertyName(for declaration: FunctionDeclSyntax) -> String {
        let functionName = declaration.name.trimmedDescription
        var notation = CamelCaseNotation(string: functionName)
        notation.removeFirst()
        return notation.joined(as: .lowerCamelCase)
    }

    static func trimmedReturnType(of declaration: FunctionDeclSyntax) -> TypeSyntax? {
        declaration.signature.returnClause?.type.trimmed
    }
}

extension MemoizedMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let parameters = try Parameters(from: node)
        let input = validate(declaration, in: context, with: parameters)

        guard let input else {
            return []
        }

        let builder = MemoizedDeclBuilder(
            declaration: input.declaration,
            trimmedReturnType: input.trimmedReturnType,
            propertyName: input.propertyName,
            lexicalContext: context.lexicalContext,
            preferredAccessControlLevel: parameters.preferredAccessControlLevel,
            preferredGlobalActorIsolation: parameters.preferredGlobalActorIsolation
        )

        return builder.build()
    }
}

extension MemoizedMacro {

    struct Parameters {

        let preferredAccessControlLevel: AccessControlLevel?
        let preferredPropertyName: String?
        let preferredGlobalActorIsolation: GlobalActorIsolation?

        init(from node: AttributeSyntax) throws {
            let extractor = ParameterExtractor(from: node)
            self.preferredAccessControlLevel = try extractor.accessControlLevel(withLabel: nil)
            self.preferredPropertyName = try extractor.rawString(withLabel: nil)
            self.preferredGlobalActorIsolation = try extractor.globalActorIsolation(withLabel: "isolation")
        }
    }
}
