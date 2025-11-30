//
//  SubclassedPublishableTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 23/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import Relay
import Testing

internal struct SubclassedPublishableTests {

    @Test
    func storedProperty() {
        var dog: Dog? = .init()
        var publishableQueue = [String]()
        nonisolated(unsafe) var observationsQueue = [Bool]()

        var completion: Subscribers.Completion<Never>?
        let cancellable = dog?.publisher.name.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = dog?.name
            } onChange: {
                observationsQueue.append(true)
            }
        }

        observe()
        #expect(publishableQueue.popFirst() == "Unknown")
        #expect(observationsQueue.popFirst() == nil)

        dog?.age = 5
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        dog?.name = "Paco"
        #expect(publishableQueue.popFirst() == "Paco")
        #expect(observationsQueue.popFirst() == true)
        observe()

        dog = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }

    @Test
    func overridenStoredProperty() {
        var dog: Dog? = .init()
        var publishableQueue = [Int]()
        nonisolated(unsafe) var observationsQueue = [Bool]()

        var completion: Subscribers.Completion<Never>?
        let cancellable = dog?.publisher.age.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = dog?.age
            } onChange: {
                observationsQueue.append(true)
            }
        }

        observe()
        #expect(publishableQueue.popFirst() == 0)
        #expect(observationsQueue.popFirst() == nil)

        dog?.name = "Paco"
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        dog?.age = 5
        #expect(publishableQueue.popFirst() == 5)
        #expect(observationsQueue.popFirst() == true)
        observe()

        dog = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }
}

extension SubclassedPublishableTests {

    @Test
    func computedProperty() {
        var dog: Dog? = .init()
        var publishableQueue = [Bool]()
        nonisolated(unsafe) var observationsQueue = [Bool]()

        var completion: Subscribers.Completion<Never>?
        let cancellable = dog?.publisher.isBulldog.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = dog?.isBulldog
            } onChange: {
                observationsQueue.append(true)
            }
        }

        observe()
        #expect(publishableQueue.popFirst() == false)
        #expect(observationsQueue.popFirst() == nil)

        dog?.breed = "Bulldog"
        #expect(publishableQueue.popFirst() == true)
        #expect(observationsQueue.popFirst() == true)
        observe()

        dog?.name = "Paco"
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        dog?.breed = nil
        #expect(publishableQueue.popFirst() == false)
        #expect(observationsQueue.popFirst() == true)
        observe()

        dog = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }

    @Test
    func overridenComputedProperty() {
        var dog: Dog? = .init()
        var publishableQueue = [String]()
        nonisolated(unsafe) var observationsQueue = [Bool]()

        var completion: Subscribers.Completion<Never>?
        let cancellable = dog?.publisher.description.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = dog?.description
            } onChange: {
                observationsQueue.append(true)
            }
        }

        observe()
        #expect(publishableQueue.popFirst() == "-, 0")
        #expect(observationsQueue.popFirst() == nil)

        dog?.breed = "Bulldog"
        #expect(publishableQueue.popFirst() == "Bulldog, 0")
        #expect(observationsQueue.popFirst() == true)
        observe()

        dog?.name = "Paco"
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        dog?.age += 1
        #expect(publishableQueue.popFirst() == "Bulldog, 1")
        #expect(observationsQueue.popFirst() == true)
        observe()

        dog = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }
}

extension SubclassedPublishableTests {

    @Test
    func willChange() {
        var dog: Dog? = .init()
        var publishableQueue = [Dog]()
        nonisolated(unsafe) var observationsQueue = [Bool]()

        var completion: Subscribers.Completion<Never>?
        let cancellable = dog?.publisher.dogWillChange.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = dog?.age
                _ = dog?.name
                _ = dog?.breed
                _ = dog?.isBulldog
            } onChange: {
                observationsQueue.append(true)
            }
        }

        observe()
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        dog?.name = "Paco"
        #expect(publishableQueue.popFirst() === dog)
        #expect(observationsQueue.popFirst() == true)
        observe()

        dog?.age += 1
        #expect(publishableQueue.popFirst() === dog)
        #expect(observationsQueue.popFirst() == true)
        observe()

        dog?.breed = "Bulldog"
        #expect(publishableQueue.popFirst() === dog)
        #expect(observationsQueue.popFirst() == true)
        observe()

        dog = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }

    @Test
    func didChange() {
        var dog: Dog? = .init()
        var publishableQueue = [Dog]()
        nonisolated(unsafe) var observationsQueue = [Bool]()

        var completion: Subscribers.Completion<Never>?
        let cancellable = dog?.publisher.dogDidChange.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = dog?.age
                _ = dog?.name
                _ = dog?.breed
                _ = dog?.isBulldog
            } onChange: {
                observationsQueue.append(true)
            }
        }

        observe()
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        dog?.name = "Paco"
        #expect(publishableQueue.popFirst() === dog)
        #expect(observationsQueue.popFirst() == true)
        observe()

        dog?.age += 1
        #expect(publishableQueue.popFirst() === dog)
        #expect(observationsQueue.popFirst() == true)
        observe()

        dog?.breed = "Bulldog"
        #expect(publishableQueue.popFirst() === dog)
        #expect(observationsQueue.popFirst() == true)
        observe()

        dog = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }
}

extension SubclassedPublishableTests {

    @Publishable @Observable
    class PublishableAnimal {

        var name = "Unknown"
        var age = 0

        var description: String {
            "\(name), \(age)"
        }
    }

    @Publishable @Observable
    final class Dog: PublishableAnimal {

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
            "\(breed ?? "-"), \(age)"
        }
    }
}

extension SubclassedPublishableTests {

    class NonPublishableAnimal {

        var name = "Unknown"
        var age = 0

        var description: String {
            "\(name), \(age)"
        }
    }

    @Publishable @Observable
    final class Cat: NonPublishableAnimal {

        var breed: String?

        var isSphynx: Bool {
            breed == "Sphynx"
        }

        @ObservationIgnored
        override var age: Int {
            didSet {
                _ = oldValue
            }
        }

        override var description: String {
            "\(breed ?? "-"), \(age)"
        }
    }
}
