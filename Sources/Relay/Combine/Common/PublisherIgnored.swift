//
//  PublisherIgnored.swift
//  Relay
//
//  Created by Kamil Strzelecki on 23/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@attached(peer)
public macro PublisherIgnored() = #externalMacro(
    module: "RelayMacros",
    type: "PublisherIgnoredMacro"
)
