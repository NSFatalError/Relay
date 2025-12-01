//
//  ImplicitlyIsolatedRelayedMacroTests.swift
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

    internal final class ImplicitlyIsolatedRelayedMacroTests: XCTestCase {

        private let macroSpecs: [String: MacroSpec] = [
            "Relayed": MacroSpec(
                type: RelayedMacro.self,
                conformances: ["Publishable", "Observable"]
            )
        ]

        func testExpansion() {
            assertMacroExpansion(
                #"""
                @available(iOS 26, macOS 26, *)
                @MainActor @Relayed
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

                    @Memoized
                    func makePlatformMemoizedProperty() -> Int {
                        platformStoredProperty
                    }
                    #endif

                    @ObservationSupressed @PublisherSupressed
                    var ignoredStoredProperty = 123

                    @ObservationSupressed
                    var observationIgnoredStoredProperty = 123

                    @PublisherSupressed
                    var publisherIgnoredStoredProperty = 123
                    
                    @PublisherSupressed
                    var publisherIgnoredComputedProperty: Int {
                        publisherIgnoredStoredProperty
                    }

                    @available(iOS 26, *)
                    @Memoized(.private)
                    func makeMemoizedProperty() -> String {
                        "\(fullName), \(age)"
                    }

                    @Memoized @PublisherSupressed
                    func makeIgnoredMemoizedProperty() -> Int {
                        publisherIgnoredStoredProperty
                    }
                }
                """#,
                expandedSource:
                #"""
                @available(iOS 26, macOS 26, *)
                @MainActor
                public final class Person {

                    static var user: Person?

                    let id: UUID
                    @RelayedProperty
                    fileprivate(set) var age: Int
                    @RelayedProperty
                    var name: String
                    @RelayedProperty

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

                    @Memoized
                    func makePlatformMemoizedProperty() -> Int {
                        platformStoredProperty
                    }
                    #endif

                    @ObservationSupressed @PublisherSupressed
                    var ignoredStoredProperty = 123

                    @ObservationSupressed
                    @RelayedProperty
                    var observationIgnoredStoredProperty = 123

                    @PublisherSupressed
                    @RelayedProperty
                    var publisherIgnoredStoredProperty = 123
                    
                    @PublisherSupressed
                    var publisherIgnoredComputedProperty: Int {
                        publisherIgnoredStoredProperty
                    }

                    @available(iOS 26, *)
                    @Memoized(.private)
                    func makeMemoizedProperty() -> String {
                        "\(fullName), \(age)"
                    }

                    @Memoized @PublisherSupressed
                    func makeIgnoredMemoizedProperty() -> Int {
                        publisherIgnoredStoredProperty
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
                            _observationIgnoredStoredProperty.send(completion: .finished)
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
                        fileprivate final let _observationIgnoredStoredProperty = PassthroughSubject<Int, Never>()
                        final var observationIgnoredStoredProperty: some Publisher<Int, Never> {
                            _storedPropertyPublisher(_observationIgnoredStoredProperty, for: \.observationIgnoredStoredProperty, object: object)
                        }

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

                        #if os(macOS)
                        final var platformMemoizedProperty: some Publisher<Int, Never> {
                            _computedPropertyPublisher(for: \.platformMemoizedProperty, object: object)
                        }
                        #endif
                        @available(iOS 26, *)
                        fileprivate final var memoizedProperty: some Publisher<String, Never> {
                            _computedPropertyPublisher(for: \.memoizedProperty, object: object)
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

                @available(iOS 26, macOS 26, *) extension Person: @MainActor Relay.Publishable {
                }

                @available(iOS 26, macOS 26, *) extension Person: nonisolated Observation.Observable {
                }
                """#,
                macroSpecs: macroSpecs
            )
        }
    }
#endif
