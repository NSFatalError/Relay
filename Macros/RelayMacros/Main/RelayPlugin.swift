//
//  RelayPlugin.swift
//  Relay
//
//  Created by Kamil Strzelecki on 11/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

#if canImport(SwiftCompilerPlugin)
    import SwiftSyntaxMacros
    import SwiftCompilerPlugin

    @main
    internal struct RelayPlugin: CompilerPlugin {

        let providingMacros: [any Macro.Type] = [
            PublishableMacro.self,
            MemoizedMacro.self
        ]
    }
#endif
