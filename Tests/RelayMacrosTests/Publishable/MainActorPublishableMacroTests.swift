//
//  MainActorPublishableMacroTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 24/08/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

#if canImport(RelayMacros)
    import RelayMacros
    import SwiftSyntaxMacrosTestSupport
    import XCTest

    internal final class MainActorPublishableMacroTests: XCTestCase {

        private let macros: [String: any Macro.Type] = [
            "Publishable": PublishableMacro.self
        ]

        func testExpansion() {
            assertMacroExpansion(
                #"""
                @MainActor @Publishable @Observable
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

                    private var initials: String {
                        get { "\(name.prefix(1))\(surname.prefix(1))" }
                        set { _ = newValue }
                    }

                    @Memoized(.public)
                    func makeLabel() -> String {
                        "\(fullName), \(age)"
                    }
                }
                """#,
                expandedSource:
                #"""
                @MainActor @Observable
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

                    private var initials: String {
                        get { "\(name.prefix(1))\(surname.prefix(1))" }
                        set { _ = newValue }
                    }

                    @Memoized(.public)
                    func makeLabel() -> String {
                        "\(fullName), \(age)"
                    }

                    /// A ``PropertyPublisher`` which exposes `Combine` publishers for all mutable 
                    /// or computed instance properties of this object.
                    ///
                    /// - Important: Don't store this instance in an external property. Accessing it after 
                    /// the original object has been deallocated may result in a crash. Always access it directly 
                    /// through the object that exposes it.
                    ///
                    public private(set) lazy var publisher = PropertyPublisher(object: self)

                    public final class PropertyPublisher: AnyPropertyPublisher<Person> {

                        deinit {
                            _age.send(completion: .finished)
                            _name.send(completion: .finished)
                            _surname.send(completion: .finished)
                        }

                        fileprivate let _age = PassthroughSubject<Int, Never>()
                        @MainActor var age: AnyPublisher<Int, Never> {
                            _storedPropertyPublisher(_age, for: \.age)
                        }
                        fileprivate let _name = PassthroughSubject<String, Never>()
                        @MainActor var name: AnyPublisher<String, Never> {
                            _storedPropertyPublisher(_name, for: \.name)
                        }
                        fileprivate let _surname = PassthroughSubject<String, Never>()
                        @MainActor public var surname: AnyPublisher<String, Never> {
                            _storedPropertyPublisher(_surname, for: \.surname)
                        }

                        @MainActor internal var fullName: AnyPublisher<String, Never> {
                            _computedPropertyPublisher(for: \.fullName)
                        }
                        @MainActor fileprivate var initials: AnyPublisher<String, Never> {
                            _computedPropertyPublisher(for: \.initials)
                        }

                        @MainActor public var label: AnyPublisher<String, Never> {
                            _computedPropertyPublisher(for: \.label)
                        }
                    }

                    private enum Observation {

                        struct ObservationRegistrar: @MainActor PublishableObservationRegistrar {

                            private let underlying = SwiftObservationRegistrar()

                            @MainActor func publish(
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
                            }

                            @MainActor private func subject(
                                for keyPath: KeyPath<Person, Int>,
                                on object: Person
                            ) -> PassthroughSubject<Int, Never>? {
                                if keyPath == \.age {
                                    return object.publisher._age
                                }
                                return nil
                            }
                            @MainActor private func subject(
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

                            nonisolated func willSet(
                                _ object: Person,
                                keyPath: KeyPath<Person, some Any>
                            ) {
                                nonisolated(unsafe) let keyPath = keyPath
                                assumeIsolatedIfNeeded {
                                    object.publisher._beginModifications()
                                    underlying.willSet(object, keyPath: keyPath)
                                }
                            }

                            nonisolated func didSet(
                                _ object: Person,
                                keyPath: KeyPath<Person, some Any>
                            ) {
                                nonisolated(unsafe) let keyPath = keyPath
                                assumeIsolatedIfNeeded {
                                    underlying.didSet(object, keyPath: keyPath)
                                    publish(object, keyPath: keyPath)
                                    object.publisher._endModifications()
                                }
                            }

                            nonisolated func access(
                                _ object: Person,
                                keyPath: KeyPath<Person, some Any>
                            ) {
                                underlying.access(object, keyPath: keyPath)
                            }

                            nonisolated func withMutation<T>(
                                of object: Person,
                                keyPath: KeyPath<Person, some Any>,
                                _ mutation: () throws -> T
                            ) rethrows -> T {
                                nonisolated(unsafe) let mutation = mutation
                                nonisolated(unsafe) let keyPath = keyPath
                                nonisolated(unsafe) var result: T!

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
                                _ operation: @MainActor () throws -> Void,
                                file: StaticString = #fileID,
                                line: UInt = #line
                            ) rethrows {
                                try withoutActuallyEscaping(operation) { operation in
                                    typealias Nonisolated = () throws -> Void
                                    let rawOperation = unsafeBitCast(operation, to: Nonisolated.self)

                                    try MainActor.shared.assumeIsolated(
                                        { _ in
                                            try rawOperation()
                                        },
                                        file: file,
                                        line: line
                                    )
                                }
                            }
                        }
                    }
                }

                extension Person: @MainActor Publishable {
                }
                """#,
                macros: macros
            )
        }
    }
#endif
