//
//  PublishableMacroTests.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

#if canImport(PublishableMacros)
    import PublishableMacros
    import SwiftSyntaxMacros
    import SwiftSyntaxMacrosTestSupport
    import XCTest

    internal final class PublishableMacroTests: XCTestCase {

        private let macros: [String: any Macro.Type] = [
            "Publishable": PublishableMacro.self
        ]

        func testExpansion() {
            assertMacroExpansion(
                #"""
                @Publishable @Observable
                public final class Person {

                    static var user: Person?

                    let id: UUID
                    fileprivate(set) var age: Int
                    var name: String

                    public var surname: String {
                        didSet {
                            print(oldValue)
                        }
                    }

                    internal var fullName: String {
                        "\(name) \(surname)"
                    }

                    package var initials: String {
                        get { "\(name.prefix(1))\(surname.prefix(1))" }
                        set { _ = newValue }
                    }
                }
                """#,
                expandedSource:
                #"""
                @Observable
                public final class Person {

                    static var user: Person?

                    let id: UUID
                    fileprivate(set) var age: Int
                    var name: String

                    public var surname: String {
                        didSet {
                            print(oldValue)
                        }
                    }

                    internal var fullName: String {
                        "\(name) \(surname)"
                    }

                    package var initials: String {
                        get { "\(name.prefix(1))\(surname.prefix(1))" }
                        set { _ = newValue }
                    }

                    public private(set) lazy var publisher = PropertyPublisher(object: self)

                    public final class PropertyPublisher: AnyPropertyPublisher<Person> {

                        deinit {
                            _age.send(completion: .finished)
                            _name.send(completion: .finished)
                            _surname.send(completion: .finished)
                        }

                        fileprivate let _age = PassthroughSubject<Int, Never>()
                        var age: AnyPublisher<Int, Never> {
                            _storedPropertyPublisher(_age, for: \.age)
                        }
                        fileprivate let _name = PassthroughSubject<String, Never>()
                        var name: AnyPublisher<String, Never> {
                            _storedPropertyPublisher(_name, for: \.name)
                        }
                        fileprivate let _surname = PassthroughSubject<String, Never>()
                        public var surname: AnyPublisher<String, Never> {
                            _storedPropertyPublisher(_surname, for: \.surname)
                        }

                        internal var fullName: AnyPublisher<String, Never> {
                            _computedPropertyPublisher(for: \.fullName)
                        }
                        package var initials: AnyPublisher<String, Never> {
                            _computedPropertyPublisher(for: \.initials)
                        }
                    }

                    private enum Observation {

                        struct ObservationRegistrar: PublishableObservationRegistrar {

                            let underlying = SwiftObservationRegistrar()

                            func publish(
                                _ object: Person,
                                keyPath: KeyPath<Person, some Any>
                            ) {
                                if let keyPath = keyPath as? KeyPath<Person, Int>,
                                   let subject = subject(for: keyPath, on: object) {
                                    subject.send(object[keyPath: keyPath])
                                    return
                                }
                                if let keyPath = keyPath as? KeyPath<Person, String>,
                                   let subject = subject(for: keyPath, on: object) {
                                    subject.send(object[keyPath: keyPath])
                                    return
                                }
                                assertionFailure("Unknown keyPath: \(keyPath)")
                            }

                            private func subject(
                                for keyPath: KeyPath<Person, Int>,
                                on object: Person
                            ) -> PassthroughSubject<Int, Never>? {
                                if keyPath == \.age {
                                    return object.publisher._age
                                }
                                return nil
                            }
                            private func subject(
                                for keyPath: KeyPath<Person, String>,
                                on object: Person
                            ) -> PassthroughSubject<String, Never>? {
                                if keyPath == \.name {
                                    return object.publisher._name
                                }
                                if keyPath == \.surname {
                                    return object.publisher._surname
                                }
                                return nil
                            }
                        }
                    }
                }

                extension Person: Publishable {
                }
                """#,
                macros: macros
            )
        }

        func testMainActorExpansion() {
            assertMacroExpansion(
                #"""
                @MainActor
                @Publishable @Observable
                public final class Person {

                    var name: String
                }
                """#,
                expandedSource:
                #"""
                @MainActor
                @Observable
                public final class Person {

                    var name: String

                    public private(set) lazy var publisher = PropertyPublisher(object: self)

                    @MainActor
                    public final class PropertyPublisher: AnyPropertyPublisher<Person> {

                        deinit {
                            _name.send(completion: .finished)
                        }

                        fileprivate let _name = PassthroughSubject<String, Never>()
                        var name: AnyPublisher<String, Never> {
                            _storedPropertyPublisher(_name, for: \.name)
                        }


                    }

                    private enum Observation {

                        @MainActor
                        struct ObservationRegistrar: MainActorPublishableObservationRegistrar {

                            let underlying = SwiftObservationRegistrar()

                            func publish(
                                _ object: Person,
                                keyPath: KeyPath<Person, some Any>
                            ) {
                                if let keyPath = keyPath as? KeyPath<Person, String>,
                                   let subject = subject(for: keyPath, on: object) {
                                    subject.send(object[keyPath: keyPath])
                                    return
                                }
                                assertionFailure("Unknown keyPath: \(keyPath)")
                            }

                            private func subject(
                                for keyPath: KeyPath<Person, String>,
                                on object: Person
                            ) -> PassthroughSubject<String, Never>? {
                                if keyPath == \.name {
                                    return object.publisher._name
                                }
                                return nil
                            }
                        }
                    }
                }

                extension Person: MainActorPublishable {
                }
                """#,
                macros: macros
            )
        }
    }
#endif
