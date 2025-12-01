//
//  PublisherSupressedMacro.swift
//  Relay
//
//  Created by Kamil Strzelecki on 22/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

public enum PublisherSupressedMacro {

    static let attribute: AttributeSyntax = "@PublisherSupressed"
}

extension PublisherSupressedMacro: PeerMacro {

    public static func expansion(
        of _: AttributeSyntax,
        providingPeersOf _: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) -> [DeclSyntax] {
        []
    }
}

extension Property {

    var isStoredPublisherTracked: Bool {
        kind == .stored
            && mutability == .mutable
            && underlying.typeScopeSpecifier == nil
            && underlying.overrideSpecifier == nil
            && !underlying.attributes.contains(like: PublisherSupressedMacro.attribute)
    }

    var isComputedPublisherTracked: Bool {
        kind == .computed
            && underlying.typeScopeSpecifier == nil
            && underlying.overrideSpecifier == nil
            && !underlying.attributes.contains(like: PublisherSupressedMacro.attribute)
    }
}

extension FunctionDeclSyntax {

    var isPublisherTracked: Bool {
        !attributes.contains(like: PublisherSupressedMacro.attribute)
    }
}
