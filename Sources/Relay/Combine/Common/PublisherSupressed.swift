//
//  PublisherSupressed.swift
//  Relay
//
//  Created by Kamil Strzelecki on 23/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

/// Disables tracking of a property through the generated ``Publishable/publisher``.
///
/// By default, an object can track any mutable or computed instance property of ``Publishable`` type that is accessible to the given object.
/// To prevent tracking of an accessible property through `Combine`, attach this macro to the property or ``Memoized(_:_:)`` method.
///
/// The `@PublisherSupressed` macro is independent of the `@ObservationIgnored` macro.
/// If you want to prevent tracking through `Observation` as well, apply both macros.
///
@attached(peer)
public macro PublisherSupressed() = #externalMacro(
    module: "RelayMacros",
    type: "PublisherSupressedMacro"
)
