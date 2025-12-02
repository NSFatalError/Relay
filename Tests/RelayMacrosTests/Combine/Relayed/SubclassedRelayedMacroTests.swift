//
//  SubclassedRelayedMacroTests.swift
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

    internal final class SubclassedRelayedMacroTests: XCTestCase {

        private let macroSpecs: [String: MacroSpec] = [
            "Relayed": MacroSpec(
                type: RelayedMacro.self,
                conformances: []
            )
        ]

        func testExpansion() {
            assertMacroExpansion(
                #"""
                @Relayed
                class Dog: Animal {

                    let id: UUID
                    var breed: String?

                    var isBulldog: Bool {
                        breed == "Bulldog"
                    }

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
                class Dog: Animal {

                    let id: UUID
                    @RelayedProperty
                    var breed: String?

                    var isBulldog: Bool {
                        breed == "Bulldog"
                    }

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

                    private let _$observationRegistrar = Observation.ObservationRegistrar()

                    private nonisolated func shouldNotifyObservers<__macro_local_1TfMu_>(
                        _ lhs: __macro_local_1TfMu_,
                        _ rhs: __macro_local_1TfMu_
                    ) -> Bool {
                        true
                    }

                    private nonisolated func shouldNotifyObservers<__macro_local_1TfMu_: Equatable>(
                        _ lhs: __macro_local_1TfMu_,
                        _ rhs: __macro_local_1TfMu_
                    ) -> Bool {
                        lhs != rhs
                    }

                    private nonisolated func shouldNotifyObservers<__macro_local_1TfMu_: AnyObject>(
                        _ lhs: __macro_local_1TfMu_,
                        _ rhs: __macro_local_1TfMu_
                    ) -> Bool {
                        lhs !== rhs
                    }

                    private nonisolated func shouldNotifyObservers<__macro_local_1TfMu_: AnyObject & Equatable>(
                        _ lhs: __macro_local_1TfMu_,
                        _ rhs: __macro_local_1TfMu_
                    ) -> Bool {
                        lhs != rhs
                    }
                }
                """#,
                macroSpecs: macroSpecs
            )
        }
    }
#endif
