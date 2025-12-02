//
//  Relayed.swift
//  Relay
//
//  Created by Kamil Strzelecki on 24/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Observation

/// A macro that adds ``Publishable`` and `Observable` conformance to classes.
///
/// - Note: This macro infers the global actor isolation of the type and applies it to the generated declarations.
/// If this causes compilation errors, use ``Relayed(isolation:)`` instead.
///
/// The `@Relayed` macro adds a new `publisher` property to your type,
/// which exposes `Combine` publishers for all mutable or computed instance properties.
///
/// If a property’s type conforms to `Equatable`, its publisher automatically removes duplicate values.
/// Just like the `Published` property wrapper, subscribing to any of the exposed publishers immediately emits the current value.
///
/// Classes to which the `@Relayed` macro has been attached can be subclassed. To generate publishers for any properties added in a subclass,
/// the macro must be applied again to the subclass definition. Subclasses should either be isolated to the same global actor as their superclass or remain `nonisolated`.
///
/// - Important: Swift Macros do not have access to full type information of expressions used in the code they’re applied to.
/// Since working with `Combine` requires knowledge of concrete types, this macro attempts to infer the types of properties when they are not explicitly specified.
/// However, this inference may fail in non-trivial cases. If the generated code fails to compile, explicitly specifying the type of the affected property should resolve the issue.
///
@attached(
    member,
    conformances: Publishable,
    Observable,
    names: named(_publisher),
    named(publisher),
    named(PropertyPublisher),
    named(_$observationRegistrar),
    named(shouldNotifyObservers)
)
@attached(
    extension,
    conformances: Publishable,
    Observable
)
@attached(
    memberAttribute
)
public macro Relayed() = #externalMacro(
    module: "RelayMacros",
    type: "RelayedMacro"
)

/// A macro that adds ``Publishable`` and `Observable` conformance to classes.
///
/// - Parameter isolation: The global actor to which the type is isolated.
/// If set to `nil`, the generated members are `nonisolated`.
/// To infer isolation automatically, use the ``Relayed()`` macro instead.
///
/// The `@Relayed` macro adds a new `publisher` property to your type,
/// which exposes `Combine` publishers for all mutable or computed instance properties.
///
/// If a property’s type conforms to `Equatable`, its publisher automatically removes duplicate values.
/// Just like the `Published` property wrapper, subscribing to any of the exposed publishers immediately emits the current value.
///
/// Classes to which the `@Relayed` macro has been attached can be subclassed. To generate publishers for any properties added in a subclass,
/// the macro must be applied again to the subclass definition. Subclasses should either be isolated to the same global actor as their superclass or remain `nonisolated`.
///
/// - Important: Swift Macros do not have access to full type information of expressions used in the code they’re applied to.
/// Since working with `Combine` requires knowledge of concrete types, this macro attempts to infer the types of properties when they are not explicitly specified.
/// However, this inference may fail in non-trivial cases. If the generated code fails to compile, explicitly specifying the type of the affected property should resolve the issue.
///
@attached(
    member,
    conformances: Publishable,
    Observable,
    names: named(_publisher),
    named(publisher),
    named(PropertyPublisher),
    named(_$observationRegistrar),
    named(shouldNotifyObservers)
)
@attached(
    extension,
    conformances: Publishable,
    Observable
)
@attached(
    memberAttribute
)
public macro Relayed(
    isolation: (any GlobalActor.Type)?
) = #externalMacro(
    module: "RelayMacros",
    type: "RelayedMacro"
)
