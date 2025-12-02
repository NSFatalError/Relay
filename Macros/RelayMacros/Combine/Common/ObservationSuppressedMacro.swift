//
//  ObservationSuppressedMacro.swift
//  Relay
//
//  Created by Kamil Strzelecki on 01/12/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

public enum ObservationSuppressedMacro {

    static let attribute: AttributeSyntax = "@ObservationSuppressed"
}

extension ObservationSuppressedMacro: PeerMacro {

    public static func expansion(
        of _: AttributeSyntax,
        providingPeersOf _: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) -> [DeclSyntax] {
        []
    }
}

extension Property {

    var isStoredObservationTracked: Bool {
        kind == .stored
            && mutability == .mutable
            && underlying.typeScopeSpecifier == nil
            && underlying.overrideSpecifier == nil
            && !underlying.attributes.contains(like: ObservationIgnoredMacro.attribute)
            && !underlying.attributes.contains(like: ObservationSuppressedMacro.attribute)
    }
}

extension FunctionDeclSyntax {

    var isObservationTracked: Bool {
        !attributes.contains(like: ObservationIgnoredMacro.attribute)
            && !attributes.contains(like: ObservationSuppressedMacro.attribute)
    }
}
