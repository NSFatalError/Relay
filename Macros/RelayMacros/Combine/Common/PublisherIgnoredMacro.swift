//
//  PublisherIgnoredMacro.swift
//  Relay
//
//  Created by Kamil Strzelecki on 22/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

public enum PublisherIgnoredMacro {

    static let attribute: AttributeSyntax = "@PublisherIgnored"
}

extension PublisherIgnoredMacro: PeerMacro {

    public static func expansion(
        of _: AttributeSyntax,
        providingPeersOf _: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) -> [DeclSyntax] {
        []
    }
}

extension Property {

    var isStoredPublishable: Bool {
        kind == .stored
        && mutability == .mutable
        && underlying.typeScopeSpecifier == nil
        && underlying.overrideSpecifier == nil
        && !underlying.attributes.contains(like: PublisherIgnoredMacro.attribute)
    }

    var isComputedPublishable: Bool {
        kind == .computed
        && underlying.typeScopeSpecifier == nil
        && underlying.overrideSpecifier == nil
        && !underlying.attributes.contains(like: PublisherIgnoredMacro.attribute)
    }
}
