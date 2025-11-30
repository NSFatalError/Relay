//
//  NonisolatedMemoizedMacroTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

#if canImport(RelayMacros)
    import RelayMacros
    import SwiftSyntaxMacrosTestSupport
    import XCTest

    internal final class NonisolatedMemoizedMacroTests: XCTestCase {

        private let macros: [String: any Macro.Type] = [
            "Memoized": MemoizedMacro.self
        ]

        func testExpansion() {
            assertMacroExpansion(
                #"""
                @MainActor @Observable
                public class Square {

                    var side = 12.3

                    @Memoized(isolation: nil)
                    private func calculateArea() -> Double {
                        side * side
                    }
                }
                """#,
                expandedSource:
                #"""
                @MainActor @Observable
                public class Square {

                    var side = 12.3
                    private func calculateArea() -> Double {
                        side * side
                    }

                    nonisolated private final var _area: Optional<Double> = nil

                    nonisolated final var area: Double {
                        if let cached = _area {
                            access(keyPath: \._area)
                            return cached
                        }

                        nonisolated(unsafe) weak var instance = self

                        @Sendable nonisolated func assumeIsolatedIfNeeded(
                            _ operation: () -> Void
                        ) {
                            operation()
                        }

                        @Sendable nonisolated func invalidateCache() {
                            assumeIsolatedIfNeeded {
                                instance?.withMutation(keyPath: \._area) {
                                    instance?._area = nil
                                }
                            }
                        }

                        return withObservationTracking {
                            let result = calculateArea()
                            _area = result
                            return result
                        } onChange: {
                            invalidateCache()
                        }
                    }
                }
                """#,
                macros: macros
            )
        }

        func testExpansionWithParameters() {
            assertMacroExpansion(
                #"""
                @MainActor @Observable
                public final class Square {

                    var side = 12.3

                    @available(macOS 26, *)
                    @Memoized(.public, "customName", isolation: nil)
                    private func calculateArea() -> Double {
                        side * side
                    }
                }
                """#,
                expandedSource:
                #"""
                @MainActor @Observable
                public final class Square {

                    var side = 12.3

                    @available(macOS 26, *)
                    private func calculateArea() -> Double {
                        side * side
                    }

                    // Stored properties cannot be made potentially unavailable
                    nonisolated private final var _customName: Optional<Double> = nil

                    @available(macOS 26, *)
                    nonisolated public final var customName: Double {
                        if let cached = _customName {
                            access(keyPath: \._customName)
                            return cached
                        }

                        nonisolated(unsafe) weak var instance = self

                        @Sendable nonisolated func assumeIsolatedIfNeeded(
                            _ operation: () -> Void
                        ) {
                            operation()
                        }

                        @Sendable nonisolated func invalidateCache() {
                            assumeIsolatedIfNeeded {
                                instance?.withMutation(keyPath: \._customName) {
                                    instance?._customName = nil
                                }
                            }
                        }

                        return withObservationTracking {
                            let result = calculateArea()
                            _customName = result
                            return result
                        } onChange: {
                            invalidateCache()
                        }
                    }
                }
                """#,
                macros: macros
            )
        }
    }
#endif
