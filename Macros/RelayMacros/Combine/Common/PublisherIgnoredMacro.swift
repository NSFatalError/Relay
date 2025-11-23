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

extension PublisherIgnoredMacro: AccessorMacro {

    public static func expansion(
        of _: AttributeSyntax,
        providingAccessorsOf _: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) -> [AccessorDeclSyntax] {
        []
    }
}
