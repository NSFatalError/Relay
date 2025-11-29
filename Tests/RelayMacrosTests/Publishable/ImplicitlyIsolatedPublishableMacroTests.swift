//
//  ImplicitlyIsolatedPublishableMacroTests.swift
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

    // swiftlint:disable:next type_body_length
    internal final class ImplicitlyIsolatedPublishableMacroTests: XCTestCase {

        private let macroSpecs: [String: MacroSpec] = [
            "Publishable": MacroSpec(
                type: PublishableMacro.self,
                conformances: ["Publishable"]
            )
        ]

        func testExpansion() {
            assertMacroExpansion(
                #"""
                @available(iOS 26, macOS 26, *)
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

                    #if os(macOS)
                    var platformStoredProperty = 123
                    
                    @available(macOS 26, *)
                    var platformComputedProperty: Int {
                        platformStoredProperty
                    }
                    #endif

                    @PublisherIgnored
                    var ignoredStoredProperty = 123
                    
                    @PublisherIgnored
                    var ignoredComputedProperty: Int {
                        ignoredStoredProperty
                    }

                    @available(iOS 26, *) @Memoized(.private)
                    func makeLabel() -> String {
                        "\(fullName), \(age)"
                    }

                    @Memoized @PublisherIgnored
                    func makeIgnoredMemoizedProperty() -> Int {
                        ignoredStoredProperty
                    }
                }
                """#,
                expandedSource:
                #"""
                @available(iOS 26, macOS 26, *)
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

                    #if os(macOS)
                    var platformStoredProperty = 123
                    
                    @available(macOS 26, *)
                    var platformComputedProperty: Int {
                        platformStoredProperty
                    }
                    #endif

                    @PublisherIgnored
                    var ignoredStoredProperty = 123
                    
                    @PublisherIgnored
                    var ignoredComputedProperty: Int {
                        ignoredStoredProperty
                    }

                    @available(iOS 26, *) @Memoized(.private)
                    func makeLabel() -> String {
                        "\(fullName), \(age)"
                    }

                    @Memoized @PublisherIgnored
                    func makeIgnoredMemoizedProperty() -> Int {
                        ignoredStoredProperty
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
                            #if os(macOS)
                            _platformStoredProperty.send(completion: .finished)
                            #endif
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
                        #if os(macOS)
                        fileprivate final let _platformStoredProperty = PassthroughSubject<Int, Never>()
                        final var platformStoredProperty: some Publisher<Int, Never> {
                            _storedPropertyPublisher(_platformStoredProperty, for: \.platformStoredProperty, object: object)
                        }
                        #endif

                        internal final var fullName: some Publisher<String, Never> {
                            _computedPropertyPublisher(for: \.fullName, object: object)
                        }
                        fileprivate final var initials: some Publisher<String, Never> {
                            _computedPropertyPublisher(for: \.initials, object: object)
                        }
                        #if os(macOS)
                        @available(macOS 26, *)
                        final var platformComputedProperty: some Publisher<Int, Never> {
                            _computedPropertyPublisher(for: \.platformComputedProperty, object: object)
                        }
                        #endif

                        @available(iOS 26, *)
                        fileprivate final var label: some Publisher<String, Never> {
                            _computedPropertyPublisher(for: \.label, object: object)
                        }
                    }

                    private enum Observation {

                        nonisolated struct ObservationRegistrar: PublishableObservationRegistrar {

                            private let underlying = SwiftObservationRegistrar()

                            @MainActor private func publish(
                                _ object: Person,
                                keyPath: KeyPath<Person, some Any>
                            ) {
                                if keyPath == \.age {
                                    object.publisher._age.send(object[keyPath: \.age])
                                    return
                                }
                                if keyPath == \.name {
                                    object.publisher._name.send(object[keyPath: \.name])
                                    return
                                }
                                if keyPath == \.surname {
                                    object.publisher._surname.send(object[keyPath: \.surname])
                                    return
                                }
                                #if os(macOS)
                                if keyPath == \.platformStoredProperty {
                                    object.publisher._platformStoredProperty.send(object[keyPath: \.platformStoredProperty])
                                    return
                                }
                                #endif
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

                @available(iOS 26, macOS 26, *) extension Person: @MainActor Publishable {
                }
                """#,
                macroSpecs: macroSpecs
            )
        }
    }
#endif
