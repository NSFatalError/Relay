//
//  MainActorPublishableTests.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 18/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import Relay
import Foundation
import Testing

@MainActor
internal struct MainActorPublishableTests {

    @Test
    func storedPropertyPublisher() {
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
    func computedPropertyPublisher() {
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

extension MainActorPublishableTests {

    @Test
    func willChangePublisher() {
        var person: Person? = .init()
        var publishableQueue = [Person]()
        nonisolated(unsafe) var observationsQueue = [Bool]()

        var completion: Subscribers.Completion<Never>?
        let cancellable = person?.publisher.willChange.sink(
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
    func didChangePublisher() {
        var person: Person? = .init()
        var publishableQueue = [Person]()
        nonisolated(unsafe) var observationsQueue = [Bool]()

        var completion: Subscribers.Completion<Never>?
        let cancellable = person?.publisher.didChange.sink(
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

extension MainActorPublishableTests {

    @MainActor @Publishable @Observable
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
    }
}
