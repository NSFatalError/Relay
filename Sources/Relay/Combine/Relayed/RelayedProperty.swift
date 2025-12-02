//
//  RelayedProperty.swift
//  Relay
//
//  Created by Kamil Strzelecki on 30/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@_documentation(
    visibility: private
)
@attached(
    accessor,
    names: named(init),
    named(get),
    named(set),
    named(_modify)
)
@attached(
    peer,
    names: prefixed(_)
)
public macro RelayedProperty() = #externalMacro(
    module: "RelayMacros",
    type: "RelayedPropertyMacro"
)
