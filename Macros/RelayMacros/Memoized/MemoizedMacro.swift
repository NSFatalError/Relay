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

    static func extract(
        from declaration: DeclSyntax
    ) -> ExtractionResult? {
        guard let declaration = declaration.as(FunctionDeclSyntax.self),
              let node = declaration.attributes.first(like: attribute),
              let parameters = try? Parameters(from: node),
              let declarationValidationResult = try? validateDeclaration(declaration)
        else {
            return nil
        }

        let propertyName = try? validatePropertyName(
            for: declarationValidationResult.declaration,
            preferred: parameters.preferredPropertyName
        )

        guard let propertyName else {
            return nil
        }

        return ExtractionResult(
            declarationValidationResult: declarationValidationResult,
            propertyName: propertyName,
            parameters: parameters
        )
    }
}

extension MemoizedMacro {

    private static func validateNode(
        attachedTo declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext,
        with parameters: Parameters
    ) throws -> ValidationResult {
        guard let enclosingClassDeclaration = context.lexicalContext.first?.as(ClassDeclSyntax.self) else {
            throw DiagnosticsError(
                node: declaration,
                message: """
                @Memoized macro can only be applied to methods declared \
                in primary definition (not extensions) of Observable classes
                """
            )
        }

        let declarationValidationResult = try validateDeclaration(declaration)
        let propertyName = try validatePropertyName(
            for: declarationValidationResult.declaration,
            preferred: parameters.preferredPropertyName
        )

        return ValidationResult(
            declaration: declarationValidationResult.declaration,
            enclosingClassDeclaration: enclosingClassDeclaration,
            trimmedReturnType: declarationValidationResult.trimmedReturnType,
            propertyName: propertyName
        )
    }

    private static func validateDeclaration(
        _ declaration: some DeclSyntaxProtocol
    ) throws -> DeclarationValidationResult {
        guard let declaration = declaration.as(FunctionDeclSyntax.self),
              let trimmedReturnType = declaration.signature.returnClause?.type.trimmed,
              declaration.signature.parameterClause.parameters.isEmpty,
              declaration.signature.effectSpecifiers == nil,
              declaration.typeScopeSpecifier == nil
        else {
            throw DiagnosticsError(
                node: declaration,
                message: """
                @Memoized macro can only be applied to non-void, non-async, non-throwing \
                methods that don't take any arguments
                """
            )
        }

        return DeclarationValidationResult(
            declaration: declaration,
            trimmedReturnType: trimmedReturnType
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
                    message: "@Memoized macro requires a non-empty property name"
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
                @Memoized macro requires a method name consisting of \
                at least two words or an explicit property name
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
        let validationResult = try validateNode(attachedTo: declaration, in: context, with: parameters)

        let builder = MemoizedDeclBuilder(
            declaration: validationResult.declaration,
            enclosingClassDeclaration: validationResult.enclosingClassDeclaration,
            trimmedReturnType: validationResult.trimmedReturnType,
            propertyName: validationResult.propertyName,
            lexicalContext: context.lexicalContext,
            preferredAccessControlLevel: parameters.preferredAccessControlLevel,
            preferredGlobalActorIsolation: parameters.preferredGlobalActorIsolation
        )

        return builder.build()
    }
}

extension MemoizedMacro {

    @dynamicMemberLookup
    struct ExtractionResult {

        let declarationValidationResult: DeclarationValidationResult
        let propertyName: String
        let parameters: Parameters

        subscript<T>(dynamicMember keyPath: KeyPath<DeclarationValidationResult, T>) -> T {
            declarationValidationResult[keyPath: keyPath]
        }

        subscript<T>(dynamicMember keyPath: KeyPath<Parameters, T>) -> T {
            parameters[keyPath: keyPath]
        }
    }

    struct DeclarationValidationResult {

        let declaration: FunctionDeclSyntax
        let trimmedReturnType: TypeSyntax
    }

    struct ValidationResult {

        let declaration: FunctionDeclSyntax
        let enclosingClassDeclaration: ClassDeclSyntax
        let trimmedReturnType: TypeSyntax
        let propertyName: String
    }

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
