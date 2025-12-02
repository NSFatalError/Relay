//
//  ObservationSuppressed.swift
//  Relay
//
//  Created by Kamil Strzelecki on 23/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

/// Disables tracking of a property through `Observation`.
///
/// - Note: This macro is functionally equivalent to the `@ObservationIgnored` macro, but can be used in contexts where that macro is not supported.
///
/// By default, an object can track any property of an `Observable` type that is accessible to it. To prevent tracking of an accessible property
/// through `Observation`, attach this macro to the property of a ``Relayed()`` class or to a ``Memoized(_:_:)`` method.
///
/// The `@ObservationSuppressed` macro is independent of the ``PublisherSuppressed()`` macro.
/// If you want to prevent tracking through `Combine` as well, apply both macros.
///
@attached(peer)
public macro ObservationSuppressed() = #externalMacro(
    module: "RelayMacros",
    type: "ObservationSuppressedMacro"
)
