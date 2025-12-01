//
//  SubclassedPublishableMacroTests.swift
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

        func testExpansion() {
            assertMacroExpansion(
                #"""
                @Publishable @CustomObservable
                class Dog: Animal {

                    let id: UUID
                    var breed: String?

                    var isBulldog: Bool {
                        breed == "Bulldog"
                    }

                    @ObservationIgnored
                    override var age: Int {
                        didSet {
                            _ = oldValue
                        }
                    }

                    override var description: String {
                        "\(breed ?? "Unknown"), \(age)"
                    }
                }
                """#,
                expandedSource:
                #"""
                @CustomObservable
                class Dog: Animal {

                    let id: UUID
                    var breed: String?

                    var isBulldog: Bool {
                        breed == "Bulldog"
                    }

                    @ObservationIgnored
                    override var age: Int {
                        didSet {
                            _ = oldValue
                        }
                    }

                    override var description: String {
                        "\(breed ?? "Unknown"), \(age)"
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
                            _breed.send(completion: .finished)
                        }

                        fileprivate final let _breed = PassthroughSubject<Optional<String>, Never>()
                        final var breed: some Publisher<Optional<String>, Never> {
                            _storedPropertyPublisher(_breed, for: \.breed, object: object)
                        }

                        final var isBulldog: some Publisher<Bool, Never> {
                            _computedPropertyPublisher(for: \.isBulldog, object: object)
                        }


                    }

                    private enum Observation {

                        nonisolated struct ObservationRegistrar: PublishableObservationRegistrar {

                            private let underlying = SwiftObservationRegistrar()

                            private func publish(
                                _ object: Dog,
                                keyPath: KeyPath<Dog, some Any>
                            ) {
                                if keyPath == \.breed {
                                    object.publisher._breed.send(object[keyPath: \.breed])
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
