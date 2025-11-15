//
//  PublishableMemoizedTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 15/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

@testable import Relay
import Testing

internal struct PublishableMemoizedTests {

    @Test
    func publisher() {
        var square: Square? = .init()
        var publishableQueue = [Double]()

        let access1 = square?.area
        #expect(access1 == 1.0)
        #expect(publishableQueue.popFirst() == nil)
        #expect(square?.calculateAreaCallsCount == 1)
        #expect(square?.isAreaCached == true)

        var completion: Subscribers.Completion<Never>?
        let cancellable = square?.publisher.area.sink( // access2
            receiveCompletion: { completion = $0 },
            receiveValue: { publishableQueue.append($0) }
        )

        #expect(publishableQueue.popFirst() == 1.0)
        #expect(square?.calculateAreaCallsCount == 1)
        #expect(square?.isAreaCached == true)

        square?.side = 2.0 // access3
        #expect(publishableQueue.popFirst() == 4.0)
        #expect(square?.calculateAreaCallsCount == 2)
        #expect(square?.isAreaCached == true)

        let access4 = square?.area
        #expect(access4 == 4.0)
        #expect(publishableQueue.popFirst() == nil)
        #expect(square?.calculateAreaCallsCount == 2)
        #expect(square?.isAreaCached == true)

        square = nil
        #expect(publishableQueue.isEmpty)
        #expect(completion == .finished)
        cancellable?.cancel()
    }
}

extension PublishableMemoizedTests {

    @Publishable @Observable
    final class Square {

        var offset = 0.0
        var side = 1.0

        @ObservationIgnored
        private(set) var calculateAreaCallsCount = 0

        var isAreaCached: Bool {
            _area != nil
        }

        @Memoized
        func calculateArea() -> Double {
            calculateAreaCallsCount += 1
            return side * side
        }
    }
}
