//
//  AnyPropertyPublisherTests.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 15/05/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import Publishable
import Testing

internal struct AnyPropertyPublisherTests {

    fileprivate struct NonEquatableStruct {}

    @Publishable @Observable
    fileprivate final class ObjectWithNonEquatableProperties {

        var storedProperty = NonEquatableStruct()
        var unrelatedProperty = 0

        var computedProperty: NonEquatableStruct {
            storedProperty
        }
    }

    @Test
    func nonEquatableStoredPropertyPublisher() {
        var object: ObjectWithNonEquatableProperties? = .init()
        var publishableQueue = [NonEquatableStruct]()
        nonisolated(unsafe) var observationsQueue: [Void] = []

        var completion: Subscribers.Completion<Never>?
        let cancellable = object?.publisher.storedProperty.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = object?.storedProperty
            } onChange: {
                observationsQueue.append(())
            }
        }

        observe()
        #expect(publishableQueue.popFirst() != nil)
        #expect(observationsQueue.popFirst() == nil)

        object?.unrelatedProperty += 1
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        object?.storedProperty = NonEquatableStruct()
        #expect(publishableQueue.popFirst() != nil)
        #expect(observationsQueue.popFirst() != nil)
        observe()

        object = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }

    @Test
    func nonEquatableComputedPropertyPublisher() {
        var object: ObjectWithNonEquatableProperties? = .init()
        var publishableQueue = [NonEquatableStruct]()
        nonisolated(unsafe) var observationsQueue: [Void] = []

        var completion: Subscribers.Completion<Never>?
        let cancellable = object?.publisher.computedProperty.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = object?.computedProperty
            } onChange: {
                observationsQueue.append(())
            }
        }

        observe()
        #expect(publishableQueue.popFirst() != nil)
        #expect(observationsQueue.popFirst() == nil)

        object?.unrelatedProperty += 1
        #expect(publishableQueue.popFirst() != nil)
        #expect(observationsQueue.popFirst() == nil)

        object?.storedProperty = NonEquatableStruct()
        #expect(publishableQueue.popFirst() != nil)
        #expect(observationsQueue.popFirst() != nil)
        observe()

        object = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }
}

extension AnyPropertyPublisherTests {

    @Publishable @Observable
    fileprivate final class ObjectWithEquatableProperties {

        var storedProperty = 0
        var unrelatedProperty = 0

        var computedProperty: Int {
            storedProperty
        }
    }

    @Test
    func equatableStoredPropertyPublisher() {
        var object: ObjectWithEquatableProperties? = .init()
        var publishableQueue = [Int]()
        nonisolated(unsafe) var observationsQueue: [Void] = []

        var completion: Subscribers.Completion<Never>?
        let cancellable = object?.publisher.storedProperty.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = object?.storedProperty
            } onChange: {
                observationsQueue.append(())
            }
        }

        observe()
        #expect(publishableQueue.popFirst() == 0)
        #expect(observationsQueue.popFirst() == nil)

        object?.unrelatedProperty += 1
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        object?.storedProperty = 0
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        object?.storedProperty += 1
        #expect(publishableQueue.popFirst() == 1)
        #expect(observationsQueue.popFirst() != nil)
        observe()

        object = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }

    @Test
    func equatableComputedPropertyPublisher() {
        var object: ObjectWithEquatableProperties? = .init()
        var publishableQueue = [Int]()
        nonisolated(unsafe) var observationsQueue: [Void] = []

        var completion: Subscribers.Completion<Never>?
        let cancellable = object?.publisher.computedProperty.sink(
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        func observe() {
            withObservationTracking {
                _ = object?.computedProperty
            } onChange: {
                observationsQueue.append(())
            }
        }

        observe()
        #expect(publishableQueue.popFirst() == 0)
        #expect(observationsQueue.popFirst() == nil)

        object?.unrelatedProperty += 1
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        object?.storedProperty = 0
        #expect(publishableQueue.popFirst() == nil)
        #expect(observationsQueue.popFirst() == nil)

        object?.storedProperty += 1
        #expect(publishableQueue.popFirst() == 1)
        #expect(observationsQueue.popFirst() != nil)
        observe()

        object = nil
        #expect(publishableQueue.isEmpty)
        #expect(observationsQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }
}
