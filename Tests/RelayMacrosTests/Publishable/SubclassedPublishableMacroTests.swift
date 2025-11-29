//
//  InferredSuperclassPublishableMacroTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 23/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

#if canImport(RelayMacros)
    import RelayMacros
    import SwiftSyntaxMacroExpansion
    import SwiftSyntaxMacrosTestSupport
    import XCTest

    internal final class SubclassedPublishableMacroTests: XCTestCase {

        private let macroSpecs: [String: MacroSpec] = [
            "Publishable": MacroSpec(
                type: PublishableMacro.self,
                conformances: []
            )
        ]

        func testExpansionWithInferredSuperclassType() {
            assertMacroExpansion(
                #"""
                @Publishable @Observable
                class Dog: Animal {
                
                    var name: String
                    
                    override var age: Int {
                        willSet {
                            print(newValue)
                        }
                    }
                }
                """#,
                expandedSource:
                #"""
                @Observable
                class Dog: Animal {

                    var name: String
                    
                    override var age: Int {
                        willSet {
                            print(newValue)
                        }
                    }

                    private final lazy var _publisher = PropertyPublisher(object: self)

                    /// A ``PropertyPublisher`` which exposes `Combine` publishers for all mutable 
                    /// or computed instance properties of this object.
                    ///
                    /// - Important: Don't store this instance in an external property. Accessing it after 
                    /// the original object has been deallocated may result in a crash. Always access it directly 
                    /// through the object that exposes it.
                    ///
                    override var publisher: PropertyPublisher {
                        _publisher
                    }

                    class PropertyPublisher: Animal.PropertyPublisher {

                        private final unowned let object: Dog

                        final var dogWillChange: some Publisher<Dog, Never> {
                            willChange.map { [unowned object] _ in
                                object
                            }
                        }

                        final var dogDidChange: some Publisher<Dog, Never> {
                            didChange.map { [unowned object] _ in
                                object
                            }
                        }

                        init(object: Dog) {
                            self.object = object
                            super.init(object: object)
                        }

                        deinit {
                            _name.send(completion: .finished)
                        }

                        fileprivate final let _name = PassthroughSubject<String, Never>()
                        final var name: some Publisher<String, Never> {
                            _storedPropertyPublisher(_name, for: \.name, object: object)
                        }
                
                
                
                
                    }

                    private enum Observation {

                        nonisolated struct ObservationRegistrar: PublishableObservationRegistrar {

                            private let underlying = SwiftObservationRegistrar()

                            private func publish(
                                _ object: Dog,
                                keyPath: KeyPath<Dog, some Any>
                            ) {
                                if keyPath == \.name {
                                    object.publisher._name.send(object[keyPath: \.name])
                                    return
                                }
                            }

                            nonisolated func willSet(
                                _ object: Dog,
                                keyPath: KeyPath<Dog, some Any>
                            ) {
                                nonisolated(unsafe) let keyPath = keyPath
                                assumeIsolatedIfNeeded {
                                    object.publisher._beginModifications()
                                    underlying.willSet(object, keyPath: keyPath)
                                }
                            }

                            nonisolated func didSet(
                                _ object: Dog,
                                keyPath: KeyPath<Dog, some Any>
                            ) {
                                nonisolated(unsafe) let keyPath = keyPath
                                assumeIsolatedIfNeeded {
                                    underlying.didSet(object, keyPath: keyPath)
                                    publish(object, keyPath: keyPath)
                                    object.publisher._endModifications()
                                }
                            }

                            nonisolated func access(
                                _ object: Dog,
                                keyPath: KeyPath<Dog, some Any>
                            ) {
                                underlying.access(object, keyPath: keyPath)
                            }

                            nonisolated func withMutation<__macro_local_1TfMu_>(
                                of object: Dog,
                                keyPath: KeyPath<Dog, some Any>,
                                _ mutation: () throws -> __macro_local_1TfMu_
                            ) rethrows -> __macro_local_1TfMu_ {
                                nonisolated(unsafe) let mutation = mutation
                                nonisolated(unsafe) let keyPath = keyPath
                                nonisolated(unsafe) var result: __macro_local_1TfMu_!

                                try assumeIsolatedIfNeeded {
                                    object.publisher._beginModifications()
                                    defer {
                                        publish(object, keyPath: keyPath)
                                        object.publisher._endModifications()
                                    }
                                    result = try underlying.withMutation(
                                        of: object,
                                        keyPath: keyPath,
                                        mutation
                                    )
                                }

                                return result
                            }

                            private nonisolated func assumeIsolatedIfNeeded(
                                _ operation: () throws -> Void
                            ) rethrows {
                                try operation()
                            }
                        }
                    }
                }
                """#,
                macroSpecs: macroSpecs
            )
        }

        func testExpansionWithExplicitSuperclassType() {
            assertMacroExpansion(
                #"""
                @Publishable(hasSuperclass: true) @Observable
                class Dog: Animal {
                
                    var name: String
                }
                """#,
                expandedSource:
                #"""
                @Observable
                class Dog: Animal {
                
                    var name: String
                
                    private final lazy var _publisher = PropertyPublisher(object: self)
                
                    /// A ``PropertyPublisher`` which exposes `Combine` publishers for all mutable 
                    /// or computed instance properties of this object.
                    ///
                    /// - Important: Don't store this instance in an external property. Accessing it after 
                    /// the original object has been deallocated may result in a crash. Always access it directly 
                    /// through the object that exposes it.
                    ///
                    override var publisher: PropertyPublisher {
                        _publisher
                    }
                
                    class PropertyPublisher: Animal.PropertyPublisher {
                
                        private final unowned let object: Dog
                
                        final var dogWillChange: some Publisher<Dog, Never> {
                            willChange.map { [unowned object] _ in
                                object
                            }
                        }
                
                        final var dogDidChange: some Publisher<Dog, Never> {
                            didChange.map { [unowned object] _ in
                                object
                            }
                        }
                
                        init(object: Dog) {
                            self.object = object
                            super.init(object: object)
                        }
                
                        deinit {
                            _name.send(completion: .finished)
                        }
                
                        fileprivate final let _name = PassthroughSubject<String, Never>()
                        final var name: some Publisher<String, Never> {
                            _storedPropertyPublisher(_name, for: \.name, object: object)
                        }
                
                
                
                
                    }
                
                    private enum Observation {
                
                        nonisolated struct ObservationRegistrar: PublishableObservationRegistrar {
                
                            private let underlying = SwiftObservationRegistrar()
                
                            private func publish(
                                _ object: Dog,
                                keyPath: KeyPath<Dog, some Any>
                            ) {
                                if keyPath == \.name {
                                    object.publisher._name.send(object[keyPath: \.name])
                                    return
                                }
                            }
                
                            nonisolated func willSet(
                                _ object: Dog,
                                keyPath: KeyPath<Dog, some Any>
                            ) {
                                nonisolated(unsafe) let keyPath = keyPath
                                assumeIsolatedIfNeeded {
                                    object.publisher._beginModifications()
                                    underlying.willSet(object, keyPath: keyPath)
                                }
                            }
                
                            nonisolated func didSet(
                                _ object: Dog,
                                keyPath: KeyPath<Dog, some Any>
                            ) {
                                nonisolated(unsafe) let keyPath = keyPath
                                assumeIsolatedIfNeeded {
                                    underlying.didSet(object, keyPath: keyPath)
                                    publish(object, keyPath: keyPath)
                                    object.publisher._endModifications()
                                }
                            }
                
                            nonisolated func access(
                                _ object: Dog,
                                keyPath: KeyPath<Dog, some Any>
                            ) {
                                underlying.access(object, keyPath: keyPath)
                            }
                
                            nonisolated func withMutation<__macro_local_1TfMu_>(
                                of object: Dog,
                                keyPath: KeyPath<Dog, some Any>,
                                _ mutation: () throws -> __macro_local_1TfMu_
                            ) rethrows -> __macro_local_1TfMu_ {
                                nonisolated(unsafe) let mutation = mutation
                                nonisolated(unsafe) let keyPath = keyPath
                                nonisolated(unsafe) var result: __macro_local_1TfMu_!
                
                                try assumeIsolatedIfNeeded {
                                    object.publisher._beginModifications()
                                    defer {
                                        publish(object, keyPath: keyPath)
                                        object.publisher._endModifications()
                                    }
                                    result = try underlying.withMutation(
                                        of: object,
                                        keyPath: keyPath,
                                        mutation
                                    )
                                }
                
                                return result
                            }
                
                            private nonisolated func assumeIsolatedIfNeeded(
                                _ operation: () throws -> Void
                            ) rethrows {
                                try operation()
                            }
                        }
                    }
                }
                """#,
                macroSpecs: macroSpecs
            )
        }

        func testExpansionWithMaskedSuperclassType() {
            assertMacroExpansion(
                #"""
                @Publishable(hasSuperclass: false) @Observable
                class Dog: Animal {
                
                    var name: String
                
                    override var age: Int {
                        willSet {
                            print(newValue)
                        }
                    }
                }
                """#,
                expandedSource:
                #"""
                @Observable
                class Dog: Animal {
                
                    var name: String
                
                    override var age: Int {
                        willSet {
                            print(newValue)
                        }
                    }
                
                    private final lazy var _publisher = PropertyPublisher(object: self)
                
                    /// A ``PropertyPublisher`` which exposes `Combine` publishers for all mutable 
                    /// or computed instance properties of this object.
                    ///
                    /// - Important: Don't store this instance in an external property. Accessing it after 
                    /// the original object has been deallocated may result in a crash. Always access it directly 
                    /// through the object that exposes it.
                    ///
                    var publisher: PropertyPublisher {
                        _publisher
                    }
                
                    class PropertyPublisher: Relay.AnyPropertyPublisher {
                
                        private final unowned let object: Dog
                
                        final var dogWillChange: some Publisher<Dog, Never> {
                            willChange.map { [unowned object] _ in
                                object
                            }
                        }
                
                        final var dogDidChange: some Publisher<Dog, Never> {
                            didChange.map { [unowned object] _ in
                                object
                            }
                        }
                
                        init(object: Dog) {
                            self.object = object
                            super.init(object: object)
                        }
                
                        deinit {
                            _name.send(completion: .finished)
                        }
                
                        fileprivate final let _name = PassthroughSubject<String, Never>()
                        final var name: some Publisher<String, Never> {
                            _storedPropertyPublisher(_name, for: \.name, object: object)
                        }
                
                
                
                
                    }
                
                    private enum Observation {
                
                        nonisolated struct ObservationRegistrar: PublishableObservationRegistrar {
                
                            private let underlying = SwiftObservationRegistrar()
                
                            private func publish(
                                _ object: Dog,
                                keyPath: KeyPath<Dog, some Any>
                            ) {
                                if keyPath == \.name {
                                    object.publisher._name.send(object[keyPath: \.name])
                                    return
                                }
                            }
                
                            nonisolated func willSet(
                                _ object: Dog,
                                keyPath: KeyPath<Dog, some Any>
                            ) {
                                nonisolated(unsafe) let keyPath = keyPath
                                assumeIsolatedIfNeeded {
                                    object.publisher._beginModifications()
                                    underlying.willSet(object, keyPath: keyPath)
                                }
                            }
                
                            nonisolated func didSet(
                                _ object: Dog,
                                keyPath: KeyPath<Dog, some Any>
                            ) {
                                nonisolated(unsafe) let keyPath = keyPath
                                assumeIsolatedIfNeeded {
                                    underlying.didSet(object, keyPath: keyPath)
                                    publish(object, keyPath: keyPath)
                                    object.publisher._endModifications()
                                }
                            }
                
                            nonisolated func access(
                                _ object: Dog,
                                keyPath: KeyPath<Dog, some Any>
                            ) {
                                underlying.access(object, keyPath: keyPath)
                            }
                
                            nonisolated func withMutation<__macro_local_1TfMu_>(
                                of object: Dog,
                                keyPath: KeyPath<Dog, some Any>,
                                _ mutation: () throws -> __macro_local_1TfMu_
                            ) rethrows -> __macro_local_1TfMu_ {
                                nonisolated(unsafe) let mutation = mutation
                                nonisolated(unsafe) let keyPath = keyPath
                                nonisolated(unsafe) var result: __macro_local_1TfMu_!
                
                                try assumeIsolatedIfNeeded {
                                    object.publisher._beginModifications()
                                    defer {
                                        publish(object, keyPath: keyPath)
                                        object.publisher._endModifications()
                                    }
                                    result = try underlying.withMutation(
                                        of: object,
                                        keyPath: keyPath,
                                        mutation
                                    )
                                }
                
                                return result
                            }
                
                            private nonisolated func assumeIsolatedIfNeeded(
                                _ operation: () throws -> Void
                            ) rethrows {
                                try operation()
                            }
                        }
                    }
                }
                """#,
                macroSpecs: macroSpecs
            )
        }
    }
#endif
