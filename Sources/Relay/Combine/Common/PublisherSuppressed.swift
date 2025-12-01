//
//  PublisherSuppressed.swift
//  Relay
//
//  Created by Kamil Strzelecki on 23/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

/// Disables tracking of a property through `Combine`.
///
/// By default, an object can track any mutable or computed instance property of a ``Publishable`` type that is accessible to it.
/// To prevent tracking of an accessible property through `Combine`, attach this macro to the property of a ``Relayed()`` or ``Publishable()`` class,
/// or to a ``Memoized(_:_:)`` method.
///
/// The `@PublisherSuppressed` macro is independent of the `@ObservationIgnored` and ``ObservationSuppressed()`` macros.
/// If you want to prevent tracking through `Observation` as well, apply both macros.
///
@attached(peer)
public macro PublisherSuppressed() = #externalMacro(
    module: "RelayMacros",
    type: "PublisherSuppressedMacro"
)
