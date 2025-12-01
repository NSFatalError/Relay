//
//  RelayPlugin.swift
//  Relay
//
//  Created by Kamil Strzelecki on 11/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
internal struct RelayPlugin: CompilerPlugin {

    let providingMacros: [any Macro.Type] = [
        PublishableMacro.self,
        RelayedMacro.self,
        RelayedPropertyMacro.self,
        PublisherSupressedMacro.self,
        ObservationSupressedMacro.self,
        MemoizedMacro.self
    ]
}
