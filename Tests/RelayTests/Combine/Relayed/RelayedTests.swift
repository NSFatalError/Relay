//
//  RelayedTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 18/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Foundation
import Relay
import Testing

internal struct RelayedTests {

    @Test
    func storedProperty() {
        var person: Person? = .init()
        var publishableQueue = [String]()
        nonisolated(unsafe) var observationsQueue = [Bool]()

        var completion: Subscribers.Completion<Never>?
        let cancellable = person?.publisher.name.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = person?.name
            } onChange: {
                observationsQueue.append(true)
            }
        }

        observe()
        #expect(publishableQueue.popFirst() == "John")
        #expect(observationsQueue.popFirst() == nil)

        person?.surname = "Strzelecki"
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        person?.name = "Kamil"
        #expect(publishableQueue.popFirst() == "Kamil")
        #expect(observationsQueue.popFirst() == true)
        observe()

        person = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }

    @Test
    func computedProperty() {
        var person: Person? = .init()
        var publishableQueue = [String]()
        nonisolated(unsafe) var observationsQueue = [Bool]()

        var completion: Subscribers.Completion<Never>?
        let cancellable = person?.publisher.fullName.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = person?.fullName
            } onChange: {
                observationsQueue.append(true)
            }
        }

        observe()
        #expect(publishableQueue.popFirst() == "John Doe")
        #expect(observationsQueue.popFirst() == nil)

        person?.surname = "Strzelecki"
        #expect(publishableQueue.popFirst() == "John Strzelecki")
        #expect(observationsQueue.popFirst() == true)
        observe()

        person?.age += 1
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        person?.name = "Kamil"
        #expect(publishableQueue.popFirst() == "Kamil Strzelecki")
        #expect(observationsQueue.popFirst() == true)
        observe()

        person = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }
}

extension RelayedTests {

    @Test
    func willChange() {
        var person: Person? = .init()
        var publishableQueue = [Person]()
        nonisolated(unsafe) var observationsQueue = [Bool]()

        var completion: Subscribers.Completion<Never>?
        let cancellable = person?.publisher.personWillChange.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = person?.age
                _ = person?.name
                _ = person?.surname
                _ = person?.fullName
            } onChange: {
                observationsQueue.append(true)
            }
        }

        observe()
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        person?.surname = "Strzelecki"
        #expect(publishableQueue.popFirst() === person)
        #expect(observationsQueue.popFirst() == true)
        observe()

        person?.age += 1
        #expect(publishableQueue.popFirst() === person)
        #expect(observationsQueue.popFirst() == true)
        observe()

        person?.name = "Kamil"
        #expect(publishableQueue.popFirst() === person)
        #expect(observationsQueue.popFirst() == true)
        observe()

        person = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }

    @Test
    func didChange() {
        var person: Person? = .init()
        var publishableQueue = [Person]()
        nonisolated(unsafe) var observationsQueue = [Bool]()

        var completion: Subscribers.Completion<Never>?
        let cancellable = person?.publisher.personDidChange.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = person?.age
                _ = person?.name
                _ = person?.surname
                _ = person?.fullName
            } onChange: {
                observationsQueue.append(true)
            }
        }

        observe()
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        person?.surname = "Strzelecki"
        #expect(publishableQueue.popFirst() === person)
        #expect(observationsQueue.popFirst() == true)
        observe()

        person?.age += 1
        #expect(publishableQueue.popFirst() === person)
        #expect(observationsQueue.popFirst() == true)
        observe()

        person?.name = "Kamil"
        #expect(publishableQueue.popFirst() === person)
        #expect(observationsQueue.popFirst() == true)
        observe()

        person = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }
}

extension RelayedTests {

    @Relayed
    final class Person {

        let id = UUID()
        var age = 25
        fileprivate(set) var name = "John"
        var surname = "Doe"

        internal var fullName: String {
            "\(name) \(surname)"
        }

        package var initials: String {
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

        @ObservationSuppressed @PublisherSuppressed
        var ignoredStoredProperty = 123

        @ObservationSuppressed
        var observationIgnoredStoredProperty = 123

        @PublisherSuppressed
        var publisherIgnoredStoredProperty = 123

        @PublisherSuppressed
        var publisherIgnoredComputedProperty: Int {
            publisherIgnoredStoredProperty
        }

        @available(iOS 26, *)
        @Memoized(.private)
        func makeMemoizedProperty() -> String {
            "\(fullName), \(age)"
        }

        @Memoized @PublisherSuppressed
        func makeIgnoredMemoizedProperty() -> Int {
            ignoredStoredProperty
        }

        #if os(macOS)
            @Memoized
            func makePlatformMemoizedProperty() -> Int {
                platformStoredProperty
            }
        #endif
    }
}
