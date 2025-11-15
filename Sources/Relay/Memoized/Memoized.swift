//
//  Memoized.swift
//  Relay
//
//  Created by Kamil Strzelecki on 14/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacrosClientSupport

@attached(peer, names: arbitrary)
public macro Memoized(
    _ accessControlLevel: AccessControlLevel? = nil,
    _ propertyName: StaticString? = nil
) = #externalMacro(
    module: "RelayMacros",
    type: "MemoizedMacro"
)

@attached(peer, names: arbitrary)
public macro Memoized<Isolation: GlobalActor>(
    _ accessControlLevel: AccessControlLevel? = nil,
    _ propertyName: StaticString? = nil,
    isolation: Isolation.Type?
) = #externalMacro(
    module: "RelayMacros",
    type: "MemoizedMacro"
)
