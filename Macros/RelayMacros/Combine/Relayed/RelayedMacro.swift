//
//  RelayedMacro.swift
//  Relay
//
//  Created by Kamil Strzelecki on 22/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

public enum RelayedMacro {

    static let attribute: AttributeSyntax = "@Relayed"

    private static func validateNode(
        attachedTo declaration: some DeclGroupSyntax,
        in _: some MacroExpansionContext
    ) throws -> ClassDeclSyntax {
        guard let declaration = declaration.as(ClassDeclSyntax.self) else {
            throw DiagnosticsError(
                node: declaration,
                message: "@Relayed macro can only be applied to classes"
            )
        }

        if let observableAttribute = declaration.attributes.first(like: ObservableMacro.attribute) {
            throw DiagnosticsError(
                node: declaration,
                message: "@Relayed macro generates its own Observable protocol conformance",
                fixIts: [
                    .remove(
                        message: "Remove @Observable macro",
                        oldNode: observableAttribute
                    )
                ]
            )
        }

        return declaration
    }
}

extension RelayedMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let declaration = try validateNode(attachedTo: declaration, in: context)
        let properties = try PropertiesParser.parse(memberBlock: declaration.memberBlock)
        let parameters = try Parameters(from: node)

        let hasPublishableSuperclass = !protocols.contains { $0.isLike("Publishable") }
        let trimmedSuperclassType = hasPublishableSuperclass ? declaration.possibleSuperclassType : nil

        let builders: [any ClassDeclBuilder] = [
            PublisherDeclBuilder(
                declaration: declaration,
                trimmedSuperclassType: trimmedSuperclassType
            ),
            PropertyPublisherDeclBuilder(
                declaration: declaration,
                properties: properties,
                trimmedSuperclassType: trimmedSuperclassType,
                preferredGlobalActorIsolation: parameters.preferredGlobalActorIsolation
            ),
            ObservableDeclBuilder(
                declaration: declaration,
                context: context
            )
        ]

        return try builders.flatMap { builder in
            try builder.build()
        }
    }
}

extension RelayedMacro: MemberAttributeMacro {

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor _: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        if try RelayedPropertyMacro.shouldAttach(to: declaration) {
            [RelayedPropertyMacro.attribute]
        } else {
            []
        }
    }
}

extension RelayedMacro: ExtensionMacro {

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard !protocols.isEmpty else {
            return []
        }

        let declaration = try validateNode(attachedTo: declaration, in: context)
        let parameters = try Parameters(from: node)
        var inheritedTypes = [AttributedTypeSyntax]()

        if protocols.contains(where: { $0.isLike("Publishable") }) {
            let globalActorIsolation = GlobalActorIsolation.resolved(
                for: declaration,
                preferred: parameters.preferredGlobalActorIsolation
            )

            inheritedTypes.append(
                AttributedTypeSyntax(
                    globalActorIsolation: globalActorIsolation,
                    baseType: "Relay.Publishable"
                )
            )
        }

        if protocols.contains(where: { $0.isLike("Observable") }) {
            inheritedTypes.append(
                AttributedTypeSyntax(
                    globalActorIsolation: .nonisolated,
                    baseType: "Observation.Observable"
                )
            )
        }

        return inheritedTypes.map { inheritedType in
            ExtensionDeclSyntax(
                attributes: declaration.availability ?? [],
                extendedType: type,
                inheritanceClause: InheritanceClauseSyntax(
                    inheritedTypes: [InheritedTypeSyntax(type: inheritedType)]
                ),
                memberBlock: "{}"
            )
        }
    }
}

extension RelayedMacro {

    private struct Parameters {

        let preferredGlobalActorIsolation: GlobalActorIsolation?

        init(from node: AttributeSyntax) throws {
            let extractor = ParameterExtractor(from: node)
            self.preferredGlobalActorIsolation = try extractor.globalActorIsolation(withLabel: "isolation")
        }
    }
}
