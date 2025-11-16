//
//  Memoized.swift
//  Relay
//
//  Created by Kamil Strzelecki on 14/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacrosClientSupport

/// A macro allowing a method to be used as a computed property, whose value will be automatically cached
/// and updated when its underlying `Observable` inputs change.
///
/// - Parameters:
///   - accessControlLevel: Access control level of the generated computed property.
///   Defaults to `nil`, meaning that no explicit access control level will be applied.
///   - propertyName: Name of the generated computed property.
///   Defaults to `nil`, meaning that the name will be derived from the method by trimming its first word.
///
/// - Note: This macro infers the global actor isolation of the method and applies it to the generated declarations.
/// If this causes compilation errors, use ``Memoized(_:_:isolation:)`` instead.
///
/// - Note: This macro works only with pure methods of classes to which the `@Observable` or `@Model` macro has been applied directly.
///
/// The `@Memoized` macro adds a new computed property to your type that returns the same value as a direct call to the original method.
/// Unlike a direct method call, this computed property automatically caches its output and returns the cached value on subsequent accesses,
/// until any of its underlying `Observable` inputs change. After an input changes, the value will be recomputed on the next access.
/// If the computed property is never accessed again, the original method will not be invoked.
///
/// Like any other property on an `Observable` type, the generated computed property can be tracked with the `Observation` APIs,
/// as well as `Combine` if the ``Publishable()`` macro has been applied to the enclosing class.
///
@attached(peer, names: arbitrary)
public macro Memoized(
    _ accessControlLevel: AccessControlLevel? = nil,
    _ propertyName: StaticString? = nil
) = #externalMacro(
    module: "RelayMacros",
    type: "MemoizedMacro"
)

/// A macro allowing a method to be used as a computed property, whose value will be automatically cached
/// and updated when its underlying `Observable` inputs change.
///
/// - Parameters:
///   - accessControlLevel: Access control level of the generated computed property.
///   Defaults to `nil`, meaning that no explicit access control level will be applied.
///   - propertyName: Name of the generated computed property.
///   Defaults to `nil`, meaning that the name will be derived from the method by trimming its first word.
///   - isolation: The global actor to which the generated computed property is isolated.
///   If set to `nil`, the property will be `nonisolated`.
///   To infer isolation automatically, use the ``Memoized(_:_:)`` macro instead.
///
/// - Note: This macro works only with pure methods of classes to which the `@Observable` or `@Model` macro has been applied directly.
///
/// The `@Memoized` macro adds a new computed property to your type that returns the same value as a direct call to the original method.
/// Unlike a direct method call, this computed property automatically caches its output and returns the cached value on subsequent accesses,
/// until any of its underlying `Observable` inputs change. After an input changes, the value will be recomputed on the next access.
/// If the computed property is never accessed again, the original method will not be invoked.
///
/// Like any other property on an `Observable` type, the generated computed property can be tracked with the `Observation` APIs,
/// as well as `Combine` if the ``Publishable()`` macro has been applied to the enclosing class.
///
@attached(peer, names: arbitrary)
public macro Memoized<Isolation: GlobalActor>(
    _ accessControlLevel: AccessControlLevel? = nil,
    _ propertyName: StaticString? = nil,
    isolation: Isolation.Type?
) = #externalMacro(
    module: "RelayMacros",
    type: "MemoizedMacro"
)
