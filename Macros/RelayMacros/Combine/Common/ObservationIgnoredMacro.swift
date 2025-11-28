//
//  ObservationIgnoredMacro.swift
//  Relay
//
//  Created by Kamil Strzelecki on 22/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

internal enum ObservationIgnoredMacro {

    static let attribute: AttributeSyntax = "@ObservationIgnored"
}

extension Property {

    var isStoredObservable: Bool {
        kind == .stored
            && mutability == .mutable
            && underlying.typeScopeSpecifier == nil
            && underlying.overrideSpecifier == nil
            && !underlying.attributes.contains(like: ObservationIgnoredMacro.attribute)
    }
}
