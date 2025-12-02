//
//  RelayedPropertyMacroTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 01/12/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

#if canImport(RelayMacros)
    import RelayMacros
    import SwiftSyntaxMacroExpansion
    import SwiftSyntaxMacrosTestSupport
    import XCTest

    internal final class RelayedPropertyMacroTests: XCTestCase {

        private let macros: [String: any Macro.Type] = [
            "RelayedProperty": RelayedPropertyMacro.self
        ]

        func testExpansion() {
            assertMacroExpansion(
                #"""
                @MainActor
                @RelayedProperty
                public internal(set) final var name = 123 {
                    didSet {
                        _ = newValue
                    }
                }
                """#,
                expandedSource:
                #"""
                @MainActor
                public internal(set) final var name {
                    didSet {
                        _ = newValue
                    }
                    @storageRestrictions(initializes: _name)
                    init(initialValue) {
                        _name = initialValue
                    }

                    get {
                        _$observationRegistrar.access(self, keyPath: \.name)
                        return _name
                    }

                    set {
                        guard shouldNotifyObservers(_name, newValue) else {
                            _name = newValue
                            return
                        }

                        publisher._beginModifications()
                        _$observationRegistrar.willSet(self, keyPath: \.name)
                        _name = newValue
                        _$observationRegistrar.didSet(self, keyPath: \.name)
                        publisher._name.send(newValue)
                        publisher._endModifications()
                    }

                    _modify {
                        publisher._beginModifications()
                        _$observationRegistrar.access(self, keyPath: \.name)
                        _$observationRegistrar.willSet(self, keyPath: \.name)

                        defer {
                            _$observationRegistrar.didSet(self, keyPath: \.name)
                            publisher._name.send(_name)
                            publisher._endModifications()
                        }

                        yield &_name
                    }
                }

                @MainActor private final var _name = 123 {
                    didSet {
                        _ = newValue
                    }
                }
                """#,
                macros: macros
            )
        }

        func testPublisherSuppressedExpansion() {
            assertMacroExpansion(
                #"""
                @MainActor
                @RelayedProperty @PublisherSuppressed
                public internal(set) final var name = 123 {
                    didSet {
                        _ = newValue
                    }
                }
                """#,
                expandedSource:
                #"""
                @MainActor
                @PublisherSuppressed
                public internal(set) final var name {
                    didSet {
                        _ = newValue
                    }
                    @storageRestrictions(initializes: _name)
                    init(initialValue) {
                        _name = initialValue
                    }

                    get {
                        _$observationRegistrar.access(self, keyPath: \.name)
                        return _name
                    }

                    set {
                        guard shouldNotifyObservers(_name, newValue) else {
                            _name = newValue
                            return
                        }

                        _$observationRegistrar.willSet(self, keyPath: \.name)
                        _name = newValue
                        _$observationRegistrar.didSet(self, keyPath: \.name)
                    }

                    _modify {
                        _$observationRegistrar.access(self, keyPath: \.name)
                        _$observationRegistrar.willSet(self, keyPath: \.name)

                        defer {
                            _$observationRegistrar.didSet(self, keyPath: \.name)
                        }

                        yield &_name
                    }
                }

                @MainActor @PublisherSuppressed private final var _name = 123 {
                    didSet {
                        _ = newValue
                    }
                }
                """#,
                macros: macros
            )
        }

        func testObservationSuppressedExpansion() {
            assertMacroExpansion(
                #"""
                @MainActor
                @RelayedProperty @ObservationSuppressed
                public internal(set) final var name = 123 {
                    didSet {
                        _ = newValue
                    }
                }
                """#,
                expandedSource:
                #"""
                @MainActor
                @ObservationSuppressed
                public internal(set) final var name {
                    didSet {
                        _ = newValue
                    }
                    @storageRestrictions(initializes: _name)
                    init(initialValue) {
                        _name = initialValue
                    }

                    get {
                        return _name
                    }

                    set {
                        guard shouldNotifyObservers(_name, newValue) else {
                            _name = newValue
                            return
                        }

                        publisher._beginModifications()
                        _name = newValue
                        publisher._name.send(newValue)
                        publisher._endModifications()
                    }

                    _modify {
                        publisher._beginModifications()

                        defer {
                            publisher._name.send(_name)
                            publisher._endModifications()
                        }

                        yield &_name
                    }
                }

                @MainActor @ObservationSuppressed private final var _name = 123 {
                    didSet {
                        _ = newValue
                    }
                }
                """#,
                macros: macros
            )
        }
    }
#endif
