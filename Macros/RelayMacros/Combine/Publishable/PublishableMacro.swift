//
//  PublishableMacro.swift
//  Relay
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

public enum PublishableMacro {

    static let attribute: AttributeSyntax = "@Publishable"

    private static func validate(
        _ node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> ClassDeclSyntax {
        guard let declaration = declaration.as(ClassDeclSyntax.self) else {
            throw DiagnosticsError(
                node: declaration,
                message: "@Publishable macro can only be applied to Observable classes"
            )
        }

        if declaration.attributes.contains(like: SwiftDataModelMacro.attribute) {
            context.diagnose(
                node: declaration,
                warningMessage: """
                @Publishable macro compiles when applied to @Model classes, \
                but internals of SwiftData are incompatible with custom ObservationRegistrar
                """,
                fixIts: [
                    .replace(
                        message: MacroExpansionFixItMessage("Remove @Publishable macro"),
                        oldNode: node,
                        newNode: "\(node.leadingTrivia)" as TokenSyntax
                    )
                ]
            )
        }

        return declaration
    }
}

extension PublishableMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let declaration = try validate(node, attachedTo: declaration, in: context)
        let properties = try PropertiesParser.parse(memberBlock: declaration.memberBlock)
        let parameters = try Parameters(from: node)

        let hasPublishableSuperclass = protocols.isEmpty
        let trimmedSuperclassType = hasPublishableSuperclass ? declaration.possibleSuperclassType : nil

        let builderTypes: [any ClassDeclBuilder] = [
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
            ObservationRegistrarDeclBuilder(
                declaration: declaration,
                properties: properties,
                preferredGlobalActorIsolation: parameters.preferredGlobalActorIsolation,
                context: context
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
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard !protocols.isEmpty else {
            return []
        }

        let declaration = try validate(node, attachedTo: declaration, in: context)
        let parameters = try Parameters(from: node)

        let globalActorIsolation = GlobalActorIsolation.resolved(
            for: declaration,
            preferred: parameters.preferredGlobalActorIsolation
        )

        return [
            .init(
                attributes: declaration.availability ?? [],
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
