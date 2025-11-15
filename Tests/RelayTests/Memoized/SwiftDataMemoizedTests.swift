//
//  SwiftDataMemoizedTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 15/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import Relay
import SwiftData
import Testing

internal struct SwiftDataMemoizedTests {

    @Test
    func access() {
        let square = Square()
        #expect(square.calculateAreaCallsCount == 0)
        #expect(!square.isAreaCached)

        square.side = 2.0
        #expect(square.calculateAreaCallsCount == 0)
        #expect(!square.isAreaCached)

        let access1 = square.area
        #expect(access1 == 4)
        #expect(square.calculateAreaCallsCount == 1)
        #expect(square.isAreaCached)

        let access2 = square.area
        #expect(access2 == 4)
        #expect(square.calculateAreaCallsCount == 1)
        #expect(square.isAreaCached)

        square.side = 3.0
        #expect(square.calculateAreaCallsCount == 1)
        #expect(!square.isAreaCached)

        let access3 = square.area
        #expect(access3 == 9)
        #expect(square.calculateAreaCallsCount == 2)
        #expect(square.isAreaCached)

        square.offset = 100.0
        #expect(square.calculateAreaCallsCount == 2)
        #expect(square.isAreaCached)
    }

    @Test
    func trackWhenCached() {
        let square = Square()
        nonisolated(unsafe) var observationsQueue = [Bool]()

        func observe() {
            withObservationTracking {
                _ = square.area
            } onChange: {
                observationsQueue.append(true)
            }
        }

        let access1 = square.area
        #expect(access1 == 1.0)
        #expect(observationsQueue.popFirst() == nil)
        #expect(square.calculateAreaCallsCount == 1)
        #expect(square.isAreaCached)

        observe() // access2
        #expect(observationsQueue.popFirst() == nil)
        #expect(square.calculateAreaCallsCount == 1)
        #expect(square.isAreaCached)

        square.side = 2.0
        #expect(observationsQueue.popFirst() == true)
        #expect(square.calculateAreaCallsCount == 1)
        #expect(!square.isAreaCached)
    }

    @Test
    func trackWhenNotCached() {
        let square = Square()
        nonisolated(unsafe) var observationsQueue = [Bool]()

        func observe() {
            withObservationTracking {
                _ = square.area
            } onChange: {
                observationsQueue.append(true)
            }
        }

        observe() // access1
        #expect(observationsQueue.popFirst() == nil)
        #expect(square.calculateAreaCallsCount == 1)
        #expect(square.isAreaCached)

        let access2 = square.area
        #expect(access2 == 1.0)
        #expect(observationsQueue.popFirst() == nil)
        #expect(square.calculateAreaCallsCount == 1)
        #expect(square.isAreaCached)

        square.side = 2.0
        #expect(observationsQueue.popFirst() == true)
        #expect(square.calculateAreaCallsCount == 1)
        #expect(!square.isAreaCached)
    }

    @MainActor @Test
    @available(macOS 26.0, macCatalyst 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    func observations() async {
        let square = Square()
        var observationsQueue = [Double]()

        let task = Task.immediate {
            let areaObservations = Observations {
                square.area
            }
            for await area in areaObservations {
                observationsQueue.append(area)
            }
        }

        try? await Task.sleep(for: .microseconds(10)) // access1 - not cached
        #expect(observationsQueue.popFirst() == 1.0)
        #expect(square.calculateAreaCallsCount == 1)
        #expect(square.isAreaCached)

        square.side = 2.0
        #expect(observationsQueue.popFirst() == nil)
        #expect(square.calculateAreaCallsCount == 1)
        #expect(!square.isAreaCached)

        try? await Task.sleep(for: .microseconds(10)) // access2 - not cached
        #expect(observationsQueue.popFirst() == 4.0)
        #expect(square.calculateAreaCallsCount == 2)
        #expect(square.isAreaCached)

        square.side = 3.0
        #expect(observationsQueue.popFirst() == nil)
        #expect(square.calculateAreaCallsCount == 2)
        #expect(!square.isAreaCached)

        square.side = 4.0
        let access3 = square.area
        #expect(access3 == 16.0)
        #expect(observationsQueue.popFirst() == nil)
        #expect(square.calculateAreaCallsCount == 3)
        #expect(square.isAreaCached)

        try? await Task.sleep(for: .microseconds(10)) // access4 - cached
        #expect(observationsQueue.popFirst() == 16.0)
        #expect(square.calculateAreaCallsCount == 3)
        #expect(square.isAreaCached)

        task.cancel()
        await task.value
        #expect(observationsQueue.isEmpty)
    }
}

extension SwiftDataMemoizedTests {

    @Model
    final class Square {

        var offset = 0.0
        var side: Double

        private(set) var calculateAreaCallsCount = 0
        var isAreaCached: Bool { _area != nil }

        init() {
            self.side = 1.0
        }

        @Memoized
        func calculateArea() -> Double {
            calculateAreaCallsCount += 1
            return side * side
        }
    }
}
