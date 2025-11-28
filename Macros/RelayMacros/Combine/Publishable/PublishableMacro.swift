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

        if declaration.attributes.contains(like: "@Model") {
            context.diagnose(
                node: declaration,
                warningMessage: """
                @Publishable macro compiles when applied to PersistentModel classes, \
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
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let declaration = try validate(node, attachedTo: declaration, in: context)
        let parameters = try Parameters(from: node)
        let inferredSuperclass = try declaration.inferredSuperclass(isExpected: parameters.hasSuperclass)
        let properties = try PropertiesParser.parse(memberBlock: declaration.memberBlock)

        let builderTypes: [any ClassDeclBuilder] = [
            PublisherDeclBuilder(
                declaration: declaration,
                trimmedSuperclassType: inferredSuperclass
            ),
            PropertyPublisherDeclBuilder(
                declaration: declaration,
                properties: properties,
                trimmedSuperclassType: inferredSuperclass,
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

        let hasSuperclass: Bool?
        let preferredGlobalActorIsolation: GlobalActorIsolation?

        init(from node: AttributeSyntax) throws {
            let extractor = ParameterExtractor(from: node)
            self.hasSuperclass = try extractor.rawBool(withLabel: "hasSuperclass")
            self.preferredGlobalActorIsolation = try extractor.globalActorIsolation(withLabel: "isolation")
        }
    }
}
