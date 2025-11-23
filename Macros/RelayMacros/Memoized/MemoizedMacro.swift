//
//  MemoizedMacro.swift
//  Relay
//
//  Created by Kamil Strzelecki on 14/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

public enum MemoizedMacro {

    static let attribute: AttributeSyntax = "@Memoized"

    private struct Input {

        let declaration: FunctionDeclSyntax
        let trimmedReturnType: TypeSyntax
        let propertyName: String
    }

    private static func validate(
        _ declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext,
        with parameters: Parameters
    ) throws -> Input {
        guard let declaration = declaration.as(FunctionDeclSyntax.self),
              let trimmedReturnType = trimmedReturnType(of: declaration),
              declaration.signature.parameterClause.parameters.isEmpty,
              declaration.signature.effectSpecifiers == nil,
              declaration.typeScopeSpecifier == nil
        else {
            throw DiagnosticsError(
                node: declaration,
                message: """
                Memoized macro can only be applied to non-void, non-async, non-throwing \
                methods that don't take any arguments
                """
            )
        }

        guard context.lexicalContext.first?.is(ClassDeclSyntax.self) == true else {
            throw DiagnosticsError(
                node: declaration,
                message: """
                Memoized macro can only be applied to methods declared \
                in body (not extension) of Observable classes
                """
            )
        }

        let propertyName = try validatePropertyName(
            for: declaration,
            preferred: parameters.preferredPropertyName
        )

        return Input(
            declaration: declaration,
            trimmedReturnType: trimmedReturnType,
            propertyName: propertyName
        )
    }

    private static func validatePropertyName(
        for declaration: FunctionDeclSyntax,
        preferred: String?
    ) throws -> String {
        if let preferred {
            guard !preferred.isEmpty else {
                throw DiagnosticsError(
                    node: declaration,
                    message: "Memoized macro requires a non-empty property name"
                )
            }
            return preferred
        }

        let inferred = defaultPropertyName(for: declaration)
        guard !inferred.isEmpty else {
            throw DiagnosticsError(
                node: declaration,
                message: """
                Memoized macro requires a method name with at least two words \
                or explicit property name
                """
            )
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
        let input = try validate(declaration, in: context, with: parameters)

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
