//
//  ObservationSupressedMemoizedMacroTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

#if canImport(RelayMacros)
    import RelayMacros
    import SwiftSyntaxMacrosTestSupport
    import XCTest

    internal final class ObservationSupressedMemoizedMacroTests: XCTestCase {

        private let macros: [String: any Macro.Type] = [
            "Memoized": MemoizedMacro.self
        ]

        func testExpansion() {
            assertMacroExpansion(
                #"""
                @Observable
                public class Square {

                    var side = 12.3

                    @Memoized @ObservationSupressed
                    private func calculateArea() -> Double {
                        side * side
                    }
                }
                """#,
                expandedSource:
                #"""
                @Observable
                public class Square {

                    var side = 12.3
                
                    @ObservationSupressed
                    private func calculateArea() -> Double {
                        side * side
                    }

                    private final var _area: Optional<Double> = nil

                    final var area: Double {
                        if let cached = _area {
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
                                instance?._area = nil
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
                @Observable
                public final class Square {

                    var side = 12.3

                    @available(macOS 26, *)
                    @Memoized(.public, "customName")
                    @ObservationSupressed
                    private func calculateArea() -> Double {
                        side * side
                    }
                }
                """#,
                expandedSource:
                #"""
                @Observable
                public final class Square {

                    var side = 12.3

                    @available(macOS 26, *)
                    @ObservationSupressed
                    private func calculateArea() -> Double {
                        side * side
                    }

                    // Stored properties cannot be made potentially unavailable
                    private final var _customName: Optional<Double> = nil

                    @available(macOS 26, *)
                    public final var customName: Double {
                        if let cached = _customName {
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
                                instance?._customName = nil
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
