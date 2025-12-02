//
//  MemoizedDeclBuilder.swift
//  Relay
//
//  Created by Kamil Strzelecki on 14/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

internal struct MemoizedDeclBuilder: FunctionDeclBuilder, PeerBuilding {

    let declaration: FunctionDeclSyntax
    let enclosingClassDeclaration: ClassDeclSyntax
    let trimmedReturnType: TypeSyntax
    let propertyName: String

    let lexicalContext: [Syntax]
    let preferredAccessControlLevel: AccessControlLevel?
    let preferredGlobalActorIsolation: GlobalActorIsolation?

    func build() -> [DeclSyntax] {
        [
            """
            \(raw: storedPropertyAvailabilityComment())\(inheritedGlobalActorIsolation)private final \
            var _\(raw: propertyName): Optional<\(trimmedReturnType)> = nil
            """,
            """
            \(inheritedAvailability)\(inheritedGlobalActorIsolation)\(preferredAccessControlLevel)final \
            var \(raw: propertyName): \(trimmedReturnType) {
                \(returnCachedIfAvailableBlock())

                nonisolated(unsafe) weak var instance = self

                \(assumeIsolatedIfNeededFunction())

                \(invalidateCacheFunction())

                \(observationTrackingBlock())
            }
            """
        ]
    }

    private func storedPropertyAvailabilityComment() -> String {
        if inheritedAvailability != nil {
            "// Stored properties cannot be made potentially unavailable\n"
        } else {
            ""
        }
    }

    private func returnCachedIfAvailableBlock() -> CodeBlockItemSyntax {
        if declaration.isObservationTracked {
            """
            if let cached = _\(raw: propertyName) {
                _$observationRegistrar.access(self, keyPath: \\.\(raw: propertyName))
                return cached
            }
            """
        } else {
            """
            if let cached = _\(raw: propertyName) {
                return cached
            }
            """
        }
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
        if enclosingClassDeclaration.attributes.contains(like: RelayedMacro.attribute),
           declaration.isPublisherTracked {
            if declaration.isObservationTracked {
                """
                @Sendable nonisolated func invalidateCache() {
                    assumeIsolatedIfNeeded {
                        guard let instance else { return }
                        instance.publisher._beginModifications()
                        instance._$observationRegistrar.willSet(instance, keyPath: \\.\(raw: propertyName))
                        instance._\(raw: propertyName) = nil
                        instance._$observationRegistrar.didSet(instance, keyPath: \\.\(raw: propertyName))
                        instance.publisher._endModifications()
                    }
                }
                """
            } else {
                """
                @Sendable nonisolated func invalidateCache() {
                    assumeIsolatedIfNeeded {
                        instance?.publisher._beginModifications()
                        instance?._\(raw: propertyName) = nil
                        instance?.publisher._endModifications()
                    }
                }
                """
            }
        } else if declaration.isObservationTracked {
            """
            @Sendable nonisolated func invalidateCache() {
                assumeIsolatedIfNeeded {
                    guard let instance else { return }
                    instance._$observationRegistrar.willSet(instance, keyPath: \\.\(raw: propertyName))
                    instance._\(raw: propertyName) = nil
                    instance._$observationRegistrar.didSet(instance, keyPath: \\.\(raw: propertyName))
                }
            }
            """
        } else {
            """
            @Sendable nonisolated func invalidateCache() {
                assumeIsolatedIfNeeded {
                    instance?._\(raw: propertyName) = nil
                }
            }
            """
        }
    }

    private func assumeIsolatedIfNeededFunction() -> CodeBlockItemSyntax {
        if let globalActor = inheritedGlobalActorIsolation?.standardizedIsolationType {
            // https://github.com/swiftlang/swift/blob/main/stdlib/public/Concurrency/MainActor.swift
            """
            @Sendable nonisolated func assumeIsolatedIfNeeded(
                _ operation: @\(globalActor) () -> Void
            ) {
                withoutActuallyEscaping(operation) { operation in
                    typealias Nonisolated = () -> Void
                    let rawOperation = unsafeBitCast(operation, to: Nonisolated.self)
                    \(globalActor).shared.assumeIsolated { _ in 
                        rawOperation()
                    }
                }
            }
            """
        } else {
            """
            @Sendable nonisolated func assumeIsolatedIfNeeded(
                _ operation: () -> Void
            ) {
                operation()
            }
            """
        }
    }
}
