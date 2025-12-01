//
//  RelayedPublisherSupressedMemoizedMacroTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

#if canImport(RelayMacros)
    import RelayMacros
    import SwiftSyntaxMacrosTestSupport
    import XCTest

    internal final class RelayedPublisherSupressedMemoizedMacroTests: XCTestCase {

        private let macros: [String: any Macro.Type] = [
            "Memoized": MemoizedMacro.self
        ]

        func testExpansion() {
            assertMacroExpansion(
                #"""
                @Relayed
                public class Square {
                
                    var side = 12.3
                
                    @Memoized @PublisherSupressed
                    private func calculateArea() -> Double {
                        side * side
                    }
                }
                """#,
                expandedSource:
                #"""
                @Relayed
                public class Square {
                
                    var side = 12.3
                
                    @PublisherSupressed
                    private func calculateArea() -> Double {
                        side * side
                    }
                
                    private final var _area: Optional<Double> = nil
                
                    final var area: Double {
                        if let cached = _area {
                            _$observationRegistrar.access(self, keyPath: \.area)
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
                                guard let instance else {
                                    return
                                }
                                instance._$observationRegistrar.willSet(instance, keyPath: \.area)
                                instance._area = nil
                                instance._$observationRegistrar.didSet(instance, keyPath: \.area)
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
                @Relayed
                public final class Square {
                
                    var side = 12.3
                
                    @available(macOS 26, *)
                    @Memoized(.public, "customName")
                    @PublisherSupressed
                    private func calculateArea() -> Double {
                        side * side
                    }
                }
                """#,
                expandedSource:
                #"""
                @Relayed
                public final class Square {
                
                    var side = 12.3
                
                    @available(macOS 26, *)
                    @PublisherSupressed
                    private func calculateArea() -> Double {
                        side * side
                    }
                
                    // Stored properties cannot be made potentially unavailable
                    private final var _customName: Optional<Double> = nil
                
                    @available(macOS 26, *)
                    public final var customName: Double {
                        if let cached = _customName {
                            _$observationRegistrar.access(self, keyPath: \.customName)
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
                                guard let instance else {
                                    return
                                }
                                instance._$observationRegistrar.willSet(instance, keyPath: \.customName)
                                instance._customName = nil
                                instance._$observationRegistrar.didSet(instance, keyPath: \.customName)
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
