//
//  AnyPropertyPublisherRelayedTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 15/05/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Relay
import Testing

internal enum AnyPropertyPublisherRelayedTests {

    struct NonEquatableType {

        fileprivate struct NonEquatableStruct {}

        fileprivate final class NonEquatableClass {}

        @Relayed
        fileprivate final class Object {

            var unrelatedProperty = 0

            var storedProperty = NonEquatableStruct()
            var computedProperty: NonEquatableStruct {
                storedProperty
            }

            var referenceTypeStoredProperty = NonEquatableClass()
            var referenceTypeComputedProperty: NonEquatableClass {
                referenceTypeStoredProperty
            }
        }

        @Test
        func storedProperty() {
            var object: Object? = .init()
            var publishableQueue = [NonEquatableStruct]()
            nonisolated(unsafe) var observationsQueue = [Bool]()

            var completion: Subscribers.Completion<Never>?
            let cancellable = object?.publisher.storedProperty.sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { publishableQueue.append($0) }
            )

            func observe() {
                withObservationTracking {
                    _ = object?.storedProperty
                } onChange: {
                    observationsQueue.append(true)
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
            #expect(observationsQueue.popFirst() == true)
            observe()

            object = nil
            #expect(publishableQueue.isEmpty)
            #expect(observationsQueue.isEmpty)
            #expect(completion == .finished)
            cancellable?.cancel()
        }

        @Test
        func referenceTypeStoredProperty() {
            var object: Object? = .init()
            var publishableQueue = [NonEquatableClass]()
            nonisolated(unsafe) var observationsQueue = [Bool]()

            var completion: Subscribers.Completion<Never>?
            let cancellable = object?.publisher.referenceTypeStoredProperty.sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { publishableQueue.append($0) }
            )

            func observe() {
                withObservationTracking {
                    _ = object?.referenceTypeStoredProperty
                } onChange: {
                    observationsQueue.append(true)
                }
            }

            observe()
            #expect(publishableQueue.popFirst() != nil)
            #expect(observationsQueue.popFirst() == nil)

            object?.unrelatedProperty += 1
            #expect(publishableQueue.popFirst() == nil)
            #expect(observationsQueue.popFirst() == nil)

            object?.referenceTypeStoredProperty = NonEquatableClass()
            #expect(publishableQueue.popFirst() != nil)
            #expect(observationsQueue.popFirst() == true)
            observe()

            object = nil
            #expect(publishableQueue.isEmpty)
            #expect(observationsQueue.isEmpty)
            #expect(completion == .finished)
            cancellable?.cancel()
        }

        @Test
        func computedProperty() {
            var object: Object? = .init()
            var publishableQueue = [NonEquatableStruct]()
            nonisolated(unsafe) var observationsQueue = [Bool]()

            var completion: Subscribers.Completion<Never>?
            let cancellable = object?.publisher.computedProperty.sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { publishableQueue.append($0) }
            )

            func observe() {
                withObservationTracking {
                    _ = object?.computedProperty
                } onChange: {
                    observationsQueue.append(true)
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
            #expect(observationsQueue.popFirst() == true)
            observe()

            object = nil
            #expect(publishableQueue.isEmpty)
            #expect(observationsQueue.isEmpty)
            #expect(completion == .finished)
            cancellable?.cancel()
        }

        @Test
        func referenceTypeComputedProperty() {
            var object: Object? = .init()
            var publishableQueue = [NonEquatableClass]()
            nonisolated(unsafe) var observationsQueue = [Bool]()

            var completion: Subscribers.Completion<Never>?
            let cancellable = object?.publisher.referenceTypeComputedProperty.sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { publishableQueue.append($0) }
            )

            func observe() {
                withObservationTracking {
                    _ = object?.referenceTypeComputedProperty
                } onChange: {
                    observationsQueue.append(true)
                }
            }

            observe()
            #expect(publishableQueue.popFirst() != nil)
            #expect(observationsQueue.popFirst() == nil)

            object?.unrelatedProperty += 1
            #expect(publishableQueue.popFirst() == nil)
            #expect(observationsQueue.popFirst() == nil)

            object?.referenceTypeStoredProperty = NonEquatableClass()
            #expect(publishableQueue.popFirst() != nil)
            #expect(observationsQueue.popFirst() == true)
            observe()

            object = nil
            #expect(publishableQueue.isEmpty)
            #expect(observationsQueue.isEmpty)
            #expect(completion == .finished)
            cancellable?.cancel()
        }
    }
}

extension AnyPropertyPublisherRelayedTests {

    struct EquatableType {

        fileprivate final class EquatableClass: Equatable {

            let value: Int

            init(value: Int) {
                self.value = value
            }

            static func == (lhs: EquatableClass, rhs: EquatableClass) -> Bool {
                lhs.value == rhs.value
            }
        }

        @Relayed
        fileprivate final class Object {

            var unrelatedProperty = 0

            var storedProperty = 0
            var computedProperty: Int {
                storedProperty
            }

            var referenceTypeStoredProperty = EquatableClass(value: 0)
            var referenceTypeComputedProperty: EquatableClass {
                referenceTypeStoredProperty
            }
        }

        @Test
        func storedProperty() {
            var object: Object? = .init()
            var publishableQueue = [Int]()
            nonisolated(unsafe) var observationsQueue = [Bool]()

            var completion: Subscribers.Completion<Never>?
            let cancellable = object?.publisher.storedProperty.sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { publishableQueue.append($0) }
            )

            func observe() {
                withObservationTracking {
                    _ = object?.storedProperty
                } onChange: {
                    observationsQueue.append(true)
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
            #expect(observationsQueue.popFirst() == true)
            observe()

            object = nil
            #expect(publishableQueue.isEmpty)
            #expect(observationsQueue.isEmpty)
            #expect(completion == .finished)
            cancellable?.cancel()
        }

        @Test
        func referenceTypeStoredProperty() {
            var object: Object? = .init()
            var publishableQueue = [EquatableClass]()
            nonisolated(unsafe) var observationsQueue = [Bool]()

            var completion: Subscribers.Completion<Never>?
            let cancellable = object?.publisher.referenceTypeStoredProperty.sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { publishableQueue.append($0) }
            )

            func observe() {
                withObservationTracking {
                    _ = object?.referenceTypeStoredProperty
                } onChange: {
                    observationsQueue.append(true)
                }
            }

            observe()
            #expect(publishableQueue.popFirst() == EquatableClass(value: 0))
            #expect(observationsQueue.popFirst() == nil)

            object?.unrelatedProperty += 1
            #expect(publishableQueue.popFirst() == nil)
            #expect(observationsQueue.popFirst() == nil)

            object?.referenceTypeStoredProperty = EquatableClass(value: 0)
            #expect(publishableQueue.popFirst() == nil)
            #expect(observationsQueue.popFirst() == nil)

            object?.referenceTypeStoredProperty = EquatableClass(value: 1)
            #expect(publishableQueue.popFirst() == EquatableClass(value: 1))
            #expect(observationsQueue.popFirst() == true)
            observe()

            object = nil
            #expect(publishableQueue.isEmpty)
            #expect(observationsQueue.isEmpty)
            #expect(completion == .finished)
            cancellable?.cancel()
        }

        @Test
        func computedProperty() {
            var object: Object? = .init()
            var publishableQueue = [Int]()
            nonisolated(unsafe) var observationsQueue = [Bool]()

            var completion: Subscribers.Completion<Never>?
            let cancellable = object?.publisher.computedProperty.sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { publishableQueue.append($0) }
            )

            func observe() {
                withObservationTracking {
                    _ = object?.computedProperty
                } onChange: {
                    observationsQueue.append(true)
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
            #expect(observationsQueue.popFirst() == true)
            observe()

            object = nil
            #expect(publishableQueue.isEmpty)
            #expect(observationsQueue.isEmpty)
            #expect(completion == .finished)
            cancellable?.cancel()
        }

        @Test
        func referenceTypeComputedProperty() {
            var object: Object? = .init()
            var publishableQueue = [EquatableClass]()
            nonisolated(unsafe) var observationsQueue = [Bool]()

            var completion: Subscribers.Completion<Never>?
            let cancellable = object?.publisher.referenceTypeComputedProperty.sink(
                receiveCompletion: { completion = $0 },
                receiveValue: { publishableQueue.append($0) }
            )

            func observe() {
                withObservationTracking {
                    _ = object?.referenceTypeComputedProperty
                } onChange: {
                    observationsQueue.append(true)
                }
            }

            observe()
            #expect(publishableQueue.popFirst() == EquatableClass(value: 0))
            #expect(observationsQueue.popFirst() == nil)

            object?.unrelatedProperty += 1
            #expect(publishableQueue.popFirst() == nil)
            #expect(observationsQueue.popFirst() == nil)

            object?.referenceTypeStoredProperty = EquatableClass(value: 0)
            #expect(publishableQueue.popFirst() == nil)
            #expect(observationsQueue.popFirst() == nil)

            object?.referenceTypeStoredProperty = EquatableClass(value: 1)
            #expect(publishableQueue.popFirst() == EquatableClass(value: 1))
            #expect(observationsQueue.popFirst() == true)
            observe()

            object = nil
            #expect(publishableQueue.isEmpty)
            #expect(observationsQueue.isEmpty)
            #expect(completion == .finished)
            cancellable?.cancel()
        }
    }
}
