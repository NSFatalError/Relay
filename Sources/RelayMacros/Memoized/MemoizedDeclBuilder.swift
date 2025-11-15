//
//  MemoizedDeclBuilder.swift
//  Relay
//
//  Created by Kamil Strzelecki on 14/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacros

internal struct MemoizedDeclBuilder: FunctionDeclBuilder, PeerBuilding {

    let declaration: FunctionDeclSyntax
    let trimmedReturnType: TypeSyntax
    let propertyName: String

    let lexicalContext: [Syntax]
    let preferredAccessControlLevel: AccessControlLevel?
    let preferredGlobalActorIsolation: GlobalActorIsolation?

    func build() -> [DeclSyntax] {
        [
            """
            \(inheritedGlobalActorIsolation)private var _\(raw: propertyName): Optional<\(trimmedReturnType)> = nil
            """,
            """
            \(inheritedGlobalActorIsolation)\(preferredAccessControlLevel)var \(raw: propertyName): \(trimmedReturnType) {
                if let cached = _\(raw: propertyName) {
                    access(keyPath: \\._\(raw: propertyName))
                    return cached
                }

                nonisolated(unsafe) weak var instance = self

                \(assumeIsolatedIfNeededFunction())

                \(invalidateCacheFunction())

                \(observationTrackingBlock())
            }
            """
        ]
    }

    private func observationTrackingBlock() -> CodeBlockItemSyntax {
        """
        return withObservationTracking {
            let result = \(declaration.name.trimmed)()
            _\(raw: propertyName) = result
            return result
        } onChange: {
            invalidateCache()
        }
        """
    }

    private func invalidateCacheFunction() -> CodeBlockItemSyntax {
        """
        @Sendable nonisolated func invalidateCache() {
            assumeIsolatedIfNeeded {
                instance?.withMutation(keyPath: \\._\(raw: propertyName)) {
                    instance?._\(raw: propertyName) = nil
                }
            }
        }
        """
    }

    private func assumeIsolatedIfNeededFunction() -> CodeBlockItemSyntax {
        if let globalActor = inheritedGlobalActorIsolation?.standardizedIsolationType {
            // https://github.com/swiftlang/swift/blob/main/stdlib/public/Concurrency/MainActor.swift
            """
            @Sendable nonisolated func assumeIsolatedIfNeeded(
                _ operation: @\(globalActor) () throws -> Void
            ) rethrows {
                try withoutActuallyEscaping(operation) { operation in
                    typealias Nonisolated = () throws -> Void
                    let rawOperation = unsafeBitCast(operation, to: Nonisolated.self)
                    try \(globalActor).shared.assumeIsolated { _ in 
                        try rawOperation()
                    }
                }
            }
            """
        } else {
            """
            @Sendable nonisolated func assumeIsolatedIfNeeded(
                _ operation: () throws -> Void
            ) rethrows {
                try operation()
            }
            """
        }
    }
}
