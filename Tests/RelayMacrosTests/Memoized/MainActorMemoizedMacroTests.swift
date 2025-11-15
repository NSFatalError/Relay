//
//  MainActorMemoizedMacroTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

#if canImport(RelayMacros)
    import PrincipleMacrosTestSupport
    import RelayMacros
    import XCTest

    internal final class MainActorMemoizedMacroTests: XCTestCase {

        private let macros: [String: any Macro.Type] = [
            "Memoized": MemoizedMacro.self
        ]

        func testExpansion() {
            assertMacroExpansion(
                #"""
                @MainActor @Observable
                public class Square {
                
                    var side = 12.3
                
                    @Memoized
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
                
                    @MainActor private var _area: Optional<Double> = nil
                
                    @MainActor var area: Double {
                        if let cached = _area {
                            access(keyPath: \._area)
                            return cached
                        }
                
                        nonisolated(unsafe) weak var instance = self
                
                        @Sendable nonisolated func assumeIsolatedIfNeeded(
                            _ operation: @MainActor () throws -> Void
                        ) rethrows {
                            try withoutActuallyEscaping(operation) { operation in
                                typealias Nonisolated = () throws -> Void
                                let rawOperation = unsafeBitCast(operation, to: Nonisolated.self)
                                try MainActor.shared.assumeIsolated { _ in
                                    try rawOperation()
                                }
                            }
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
                
                    @Memoized(.public, "customName")
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
                    private func calculateArea() -> Double {
                        side * side
                    }
                
                    @MainActor private var _customName: Optional<Double> = nil
                
                    @MainActor public var customName: Double {
                        if let cached = _customName {
                            access(keyPath: \._customName)
                            return cached
                        }
                
                        nonisolated(unsafe) weak var instance = self
                
                        @Sendable nonisolated func assumeIsolatedIfNeeded(
                            _ operation: @MainActor () throws -> Void
                        ) rethrows {
                            try withoutActuallyEscaping(operation) { operation in
                                typealias Nonisolated = () throws -> Void
                                let rawOperation = unsafeBitCast(operation, to: Nonisolated.self)
                                try MainActor.shared.assumeIsolated { _ in
                                    try rawOperation()
                                }
                            }
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
