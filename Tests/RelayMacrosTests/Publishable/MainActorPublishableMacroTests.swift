//
//  MainActorPublishableMacroTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 24/08/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

#if canImport(RelayMacros)
    import RelayMacros
    import SwiftSyntaxMacroExpansion
    import SwiftSyntaxMacrosTestSupport
    import XCTest

    internal final class MainActorPublishableMacroTests: XCTestCase {

        private let macroSpecs: [String: MacroSpec] = [
            "Publishable": MacroSpec(
                type: PublishableMacro.self,
                conformances: ["Publishable"]
            )
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

                    private final lazy var _publisher = PropertyPublisher(object: self)
                
                    /// A ``PropertyPublisher`` which exposes `Combine` publishers for all mutable 
                    /// or computed instance properties of this object.
                    ///
                    /// - Important: Don't store this instance in an external property. Accessing it after 
                    /// the original object has been deallocated may result in a crash. Always access it directly 
                    /// through the object that exposes it.
                    ///
                    public var publisher: PropertyPublisher {
                        _publisher
                    }
                
                    @MainActor public final class PropertyPublisher: Relay.AnyPropertyPublisher {
                
                        private final unowned let object: Person
                
                        public final var personWillChange: some Publisher<Person, Never> {
                            willChange.map { [unowned object] _ in
                                object
                            }
                        }
                
                        public final var personDidChange: some Publisher<Person, Never> {
                            didChange.map { [unowned object] _ in
                                object
                            }
                        }
                
                        public init(object: Person) {
                            self.object = object
                            super.init(object: object)
                        }
                
                        @MainActor deinit {
                            _age.send(completion: .finished)
                            _name.send(completion: .finished)
                            _surname.send(completion: .finished)
                        }

                        fileprivate final let _age = PassthroughSubject<Int, Never>()
                        final var age: some Publisher<Int, Never> {
                            _storedPropertyPublisher(_age, for: \.age, object: object)
                        }
                        fileprivate final let _name = PassthroughSubject<String, Never>()
                        final var name: some Publisher<String, Never> {
                            _storedPropertyPublisher(_name, for: \.name, object: object)
                        }
                        fileprivate final let _surname = PassthroughSubject<String, Never>()
                        public final var surname: some Publisher<String, Never> {
                            _storedPropertyPublisher(_surname, for: \.surname, object: object)
                        }

                        internal final var fullName: some Publisher<String, Never> {
                            _computedPropertyPublisher(for: \.fullName, object: object)
                        }
                        fileprivate final var initials: some Publisher<String, Never> {
                            _computedPropertyPublisher(for: \.initials, object: object)
                        }

                        public final var label: some Publisher<String, Never> {
                            _computedPropertyPublisher(for: \.label, object: object)
                        }
                    }

                    private enum Observation {

                        nonisolated struct ObservationRegistrar: @MainActor PublishableObservationRegistrar {

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

                            nonisolated func withMutation<__macro_local_1TfMu_>(
                                of object: Person,
                                keyPath: KeyPath<Person, some Any>,
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
                macroSpecs: macroSpecs
            )
        }

        func testExpansionWithExplicitIsolation() {
            assertMacroExpansion(
                #"""
                @CustomActor @Publishable(isolation: MainActor.self) @Observable
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
                @CustomActor @Observable
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
                
                    private final lazy var _publisher = PropertyPublisher(object: self)
                
                    /// A ``PropertyPublisher`` which exposes `Combine` publishers for all mutable 
                    /// or computed instance properties of this object.
                    ///
                    /// - Important: Don't store this instance in an external property. Accessing it after 
                    /// the original object has been deallocated may result in a crash. Always access it directly 
                    /// through the object that exposes it.
                    ///
                    public var publisher: PropertyPublisher {
                        _publisher
                    }
                
                    @MainActor public final class PropertyPublisher: Relay.AnyPropertyPublisher {
                
                        private final unowned let object: Person
                
                        public final var personWillChange: some Publisher<Person, Never> {
                            willChange.map { [unowned object] _ in
                                object
                            }
                        }
                
                        public final var personDidChange: some Publisher<Person, Never> {
                            didChange.map { [unowned object] _ in
                                object
                            }
                        }
                
                        public init(object: Person) {
                            self.object = object
                            super.init(object: object)
                        }
                
                        @MainActor deinit {
                            _age.send(completion: .finished)
                            _name.send(completion: .finished)
                            _surname.send(completion: .finished)
                        }
                
                        fileprivate final let _age = PassthroughSubject<Int, Never>()
                        final var age: some Publisher<Int, Never> {
                            _storedPropertyPublisher(_age, for: \.age, object: object)
                        }
                        fileprivate final let _name = PassthroughSubject<String, Never>()
                        final var name: some Publisher<String, Never> {
                            _storedPropertyPublisher(_name, for: \.name, object: object)
                        }
                        fileprivate final let _surname = PassthroughSubject<String, Never>()
                        public final var surname: some Publisher<String, Never> {
                            _storedPropertyPublisher(_surname, for: \.surname, object: object)
                        }
                
                        internal final var fullName: some Publisher<String, Never> {
                            _computedPropertyPublisher(for: \.fullName, object: object)
                        }
                        fileprivate final var initials: some Publisher<String, Never> {
                            _computedPropertyPublisher(for: \.initials, object: object)
                        }
                
                        public final var label: some Publisher<String, Never> {
                            _computedPropertyPublisher(for: \.label, object: object)
                        }
                    }
                
                    private enum Observation {
                
                        nonisolated struct ObservationRegistrar: @MainActor PublishableObservationRegistrar {
                
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
                
                            nonisolated func withMutation<__macro_local_1TfMu_>(
                                of object: Person,
                                keyPath: KeyPath<Person, some Any>,
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
                macroSpecs: macroSpecs
            )
        }
    }
#endif
