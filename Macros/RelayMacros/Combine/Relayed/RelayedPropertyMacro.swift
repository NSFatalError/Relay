//
//  RelayedPropertyMacro.swift
//  Relay
//
//  Created by Kamil Strzelecki on 24/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

public enum RelayedPropertyMacro {

    static let attribute: AttributeSyntax = "@RelayedProperty"

    static func shouldAttach(
        to declaration: some DeclSyntaxProtocol
    ) throws -> Bool {
        if let property = try validateNode(attachedTo: declaration) {
            !property.attributes.contains(like: attribute)
        } else {
            false
        }
    }
}

extension RelayedPropertyMacro {

    private static func validateNode(
        attachedTo declaration: some DeclSyntaxProtocol
    ) throws -> Property? {
        if let property = try PropertiesParser.parseStandalone(declaration: declaration),
           property.isStoredObservationTracked || property.isStoredPublisherTracked {
            property
        } else {
            nil
        }
    }
}

extension RelayedPropertyMacro: AccessorMacro {

    public static func expansion(
        of _: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let property = try validateNode(attachedTo: declaration) else {
            return []
        }

        let builder = RelayedPropertyDeclAccessorBuilder(declaration: property)
        return builder.buildAccessors()
    }
}

extension RelayedPropertyMacro: PeerMacro {

    public static func expansion(
        of _: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let property = try validateNode(attachedTo: declaration) else {
            return []
        }

        let attributes = property.attributes.filter { attribute in
            attribute.attribute?.isLike(RelayedPropertyMacro.attribute) != true
        }

        let modifiers = property.modifiers.withAccessControlLevel(.private)
        let name: TokenSyntax = "_\(property.trimmedName)"

        let pattern = PatternSyntax(IdentifierPatternSyntax(identifier: name))
        let binding = property.binding.with(\.pattern, pattern)
        var bindings = property.bindings

        bindings.replaceSubrange(
            bindings.startIndex ..< bindings.endIndex,
            with: CollectionOfOne(binding)
        )

        let storage = property.trimmed
            .with(\.attributes, attributes)
            .with(\.modifiers, modifiers)
            .with(\.bindings, bindings)

        return [DeclSyntax(storage)]
    }
}
