//
//  PublishableMacro.swift
//  Relay
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

public enum PublishableMacro {

    private static func validate(
        _ declaration: some DeclGroupSyntax
    ) throws -> ClassDeclSyntax {
        guard let declaration = declaration.as(ClassDeclSyntax.self),
              declaration.isFinal
        else {
            throw DiagnosticsError(
                node: declaration,
                message: "Publishable macro can only be applied to final Observable classes"
            )
        }
        return declaration
    }
}

extension PublishableMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let declaration = try validate(declaration)
        let parameters = try Parameters(from: node)

        let properties = try PropertiesParser.parse(
            memberBlock: declaration.memberBlock
        )

        let builderTypes: [any ClassDeclBuilder] = [
            PublisherDeclBuilder(
                declaration: declaration,
                properties: properties
            ),
            PropertyPublisherDeclBuilder(
                declaration: declaration,
                properties: properties,
                preferredGlobalActorIsolation: parameters.preferredGlobalActorIsolation
            ),
            ObservationRegistrarDeclBuilder(
                declaration: declaration,
                properties: properties,
                preferredGlobalActorIsolation: parameters.preferredGlobalActorIsolation
            )
        ]

        return try builderTypes.flatMap { builderType in
            try builderType.build()
        }
    }
}

extension PublishableMacro: ExtensionMacro {

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let declaration = try validate(declaration)
        let parameters = try Parameters(from: node)

        let globalActorIsolation = GlobalActorIsolation.resolved(
            for: declaration,
            preferred: parameters.preferredGlobalActorIsolation
        )

        return [
            .init(
                extendedType: type,
                inheritanceClause: .init(
                    inheritedTypes: [
                        InheritedTypeSyntax(
                            type: AttributedTypeSyntax(
                                globalActorIsolation: globalActorIsolation,
                                baseType: IdentifierTypeSyntax(name: "Publishable")
                            )
                        )
                    ]
                ),
                memberBlock: "{}"
            )
        ]
    }
}

extension PublishableMacro {

    private struct Parameters {

        let preferredGlobalActorIsolation: GlobalActorIsolation?

        init(from node: AttributeSyntax) throws {
            let extractor = ParameterExtractor(from: node)
            self.preferredGlobalActorIsolation = try extractor.globalActorIsolation(withLabel: "isolation")
        }
    }
}
