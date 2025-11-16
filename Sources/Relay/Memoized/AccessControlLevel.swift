//
//  AccessControlLevel.swift
//  Relay
//
//  Created by Kamil Strzelecki on 13/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

public enum AccessControlLevel: Hashable {

    case `private`
    case `fileprivate`
    case `internal`
    case package
    case `public`
    case open
}
