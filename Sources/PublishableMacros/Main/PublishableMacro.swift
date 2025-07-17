//
//  PublishableMacro.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacros

public enum PublishableMacro {

    private static func validate(
        _ declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) -> ClassDeclSyntax? {
        guard let declaration = declaration as? ClassDeclSyntax,
              declaration.attributes.contains(likeOneOf: "@Observable", "@Model"),
              declaration.isFinal
        else {
            context.diagnose(
                node: declaration,
                errorMessage: "Publishable macro can only be applied to final @Observable or @Model classes"
            )
            return nil
        }
        return declaration
    }
}

extension PublishableMacro: MemberMacro {

    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declaration = validate(declaration, in: context) else {
            return []
        }

        let properties = PropertiesParser.parse(
            memberBlock: declaration.memberBlock,
            in: context
        )

        // Propagate @MainActor isolation if declared on the type
        let isMainActor = declaration.attributes.contains(likeOneOf: "@MainActor")
        let builderTypes: [any ClassDeclBuilder] = [
            PublisherDeclBuilder(declaration: declaration, properties: properties),
            PropertyPublisherDeclBuilder(declaration: declaration, properties: properties, mainActor: isMainActor),
            ObservationRegistrarDeclBuilder(declaration: declaration, properties: properties, mainActor: isMainActor)
        ]

        return try builderTypes.flatMap { builderType in
            try builderType.build()
        }
    }
}

extension PublishableMacro: ExtensionMacro {

    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard validate(declaration, in: context) != nil else {
            return []
        }

        return [
            .init(
                extendedType: type,
                inheritanceClause: .init(
                    inheritedTypes: [
                        .init(type: IdentifierTypeSyntax(name: "Publishable"))
                    ]
                ),
                memberBlock: "{}"
            )
        ]
    }
}
