//
//  Publishable.swift
//  Relay
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

/// A macro that adds ``Publishable-protocol`` conformance to `Observable` types.
///
/// - Note: This macro infers the global actor isolation of the type and applies it to the generated declarations.
/// If this causes compilation errors, use ``Publishable(isolation:)`` instead.
///
/// - Note: This macro works only with `final` classes to which the `@Observable` or `@Model` macro has been applied.
///
/// The `@Publishable` macro adds a new `publisher` property to your type,
/// which exposes `Combine` publishers for all mutable or computed instance properties.
///
/// If a property’s type conforms to `Equatable`, its publisher automatically removes duplicate values.
/// Just like the `Published` property wrapper, subscribing to any of the exposed publishers immediately emits the current value.
///
/// - Important: Swift Macros do not have access to full type information of expressions used in the code they’re applied to.
/// Since working with `Combine` requires knowledge of concrete types, this macro attempts to infer the types of properties when they are not explicitly specified.
/// However, this inference may fail in non-trivial cases. If the generated code fails to compile, explicitly specifying the type of the affected property should resolve the issue.
///
@attached(
    member,
    names: named(_publisher),
    named(publisher),
    named(PropertyPublisher),
    named(Observation)
)
@attached(
    extension,
    conformances: Publishable
)
public macro Publishable(
    hasSuperclass: Bool = false
) = #externalMacro(
    module: "RelayMacros",
    type: "PublishableMacro"
)

/// A macro that adds ``Publishable-protocol`` conformance to `Observable` types.
///
/// - Parameter isolation: The global actor to which the type is isolated.
/// If set to `nil`, the generated members are `nonisolated`.
/// To infer isolation automatically, use the ``Publishable()`` macro instead.
///
/// - Note: This macro works only with `final` classes to which the `@Observable` or `@Model` macro has been applied directly.
///
/// The `@Publishable` macro adds a new `publisher` property to your type,
/// which exposes `Combine` publishers for all mutable or computed instance properties.
///
/// If a property’s type conforms to `Equatable`, its publisher automatically removes duplicate values.
/// Just like the `Published` property wrapper, subscribing to any of the exposed publishers immediately emits the current value.
///
/// - Important: Swift Macros do not have access to full type information of expressions used in the code they’re applied to.
/// Since working with `Combine` requires knowledge of concrete types, this macro attempts to infer the types of properties when they are not explicitly specified.
/// However, this inference may fail in non-trivial cases. If the generated code fails to compile, explicitly specifying the type of the affected property should resolve the issue.
///
@attached(
    member,
    names: named(_publisher),
    named(publisher),
    named(PropertyPublisher),
    named(Observation)
)
@attached(
    extension,
    conformances: Publishable
)
public macro Publishable(
    hasSuperclass: Bool = false,
    isolation: MainActor.Type?
) = #externalMacro(
    module: "RelayMacros",
    type: "PublishableMacro"
)

/// A macro that adds ``Publishable-protocol`` conformance to `Observable` types.
///
/// - Parameter isolation: The global actor to which the type is isolated.
/// If set to `nil`, the generated members are `nonisolated`.
/// To infer isolation automatically, use the ``Publishable()`` macro instead.
///
/// - Note: This macro works only with `final` classes to which the `@Observable` or `@Model` macro has been applied directly.
///
/// The `@Publishable` macro adds a new `publisher` property to your type,
/// which exposes `Combine` publishers for all mutable or computed instance properties.
///
/// If a property’s type conforms to `Equatable`, its publisher automatically removes duplicate values.
/// Just like the `Published` property wrapper, subscribing to any of the exposed publishers immediately emits the current value.
///
/// - Important: Swift Macros do not have access to full type information of expressions used in the code they’re applied to.
/// Since working with `Combine` requires knowledge of concrete types, this macro attempts to infer the types of properties when they are not explicitly specified.
/// However, this inference may fail in non-trivial cases. If the generated code fails to compile, explicitly specifying the type of the affected property should resolve the issue.
///
@attached(
    member,
    names: named(_publisher),
    named(publisher),
    named(PropertyPublisher),
    named(Observation)
)
@attached(
    extension,
    conformances: Publishable
)
public macro Publishable<Isolation: GlobalActor>(
    hasSuperclass: Bool = false,
    isolation: Isolation.Type
) = #externalMacro(
    module: "RelayMacros",
    type: "PublishableMacro"
)
