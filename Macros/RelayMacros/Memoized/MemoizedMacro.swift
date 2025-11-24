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
}

extension MemoizedMacro {

    struct Input {

        let declaration: FunctionDeclSyntax
        let trimmedReturnType: TypeSyntax
        let propertyName: String
    }

    static func validate(
        _ declaration: some DeclSyntaxProtocol,
        with parameters: Parameters
    ) throws -> Input {
        guard let declaration = declaration.as(FunctionDeclSyntax.self),
              let trimmedReturnType = declaration.signature.returnClause?.type.trimmed,
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

    private static func validate(
        _ declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext,
        with parameters: Parameters
    ) throws -> Input {
        guard context.lexicalContext.first?.is(ClassDeclSyntax.self) == true else {
            throw DiagnosticsError(
                node: declaration,
                message: """
                Memoized macro can only be applied to methods declared \
                in body (not extension) of Observable classes
                """
            )
        }

        return try validate(
            declaration,
            with: parameters
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

        let functionName = declaration.name.trimmedDescription
        var notation = CamelCaseNotation(string: functionName)
        notation.removeFirst()
        let inferred = notation.joined(as: .lowerCamelCase)

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
