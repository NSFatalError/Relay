//
//  PublishableMemoizedTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 15/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Relay
import Testing

internal struct PublishableMemoizedTests {

    @Test
    func independent() {
        let cube = Cube()
        var queue = [Double]()

        let access1 = cube.baseArea
        #expect(access1 == 1.0)
        #expect(queue.popFirst() == nil)
        #expect(cube.calculateBaseAreaCallsCount == 1)
        #expect(cube.isBaseAreaCached)

        // access2
        let cancellable = cube.publisher.baseArea.sink { baseArea in
            queue.append(baseArea)
        }

        #expect(queue.popFirst() == 1.0)
        #expect(cube.calculateBaseAreaCallsCount == 1)
        #expect(cube.isBaseAreaCached)

        cube.x = 2.0 // access3
        #expect(queue.popFirst() == 2.0)
        #expect(cube.calculateBaseAreaCallsCount == 2)
        #expect(cube.isBaseAreaCached)

        let access4 = cube.baseArea
        #expect(access4 == 2.0)
        #expect(queue.popFirst() == nil)
        #expect(cube.calculateBaseAreaCallsCount == 2)
        #expect(cube.isBaseAreaCached)

        cancellable.cancel()
        #expect(queue.isEmpty)

        cube.y = 3.0
        #expect(cube.calculateBaseAreaCallsCount == 2)
        #expect(!cube.isBaseAreaCached)
    }

    @Test
    func dependent() {
        let cube = Cube()
        var volumeQueue = [Double]()
        var baseAreaQueue = [Double]()

        let accessBaseArea1 = cube.baseArea
        #expect(accessBaseArea1 == 1.0)
        #expect(baseAreaQueue.popFirst() == nil)
        #expect(cube.calculateBaseAreaCallsCount == 1)
        #expect(cube.isBaseAreaCached)
        #expect(volumeQueue.popFirst() == nil)
        #expect(cube.calculateVolumeCallsCount == 0)
        #expect(!cube.isVolumeCached)

        // accessVolume1, accessBaseArea2, accessBaseArea3
        let volumeCancellable = cube.publisher.volume.sink { volume in
            volumeQueue.append(volume)
        }
        let baseAreaCancellable = cube.publisher.baseArea.sink { baseArea in
            baseAreaQueue.append(baseArea)
        }

        #expect(baseAreaQueue.popFirst() == 1.0)
        #expect(cube.calculateBaseAreaCallsCount == 1)
        #expect(cube.isBaseAreaCached)
        #expect(volumeQueue.popFirst() == 1.0)
        #expect(cube.calculateVolumeCallsCount == 1)
        #expect(cube.isVolumeCached)

        cube.x = 2.0 // accessVolume2, accessBaseArea4, accessBaseArea5
        #expect(baseAreaQueue.popFirst() == 2.0)
        #expect(cube.calculateBaseAreaCallsCount == 2)
        #expect(cube.isBaseAreaCached)
        #expect(volumeQueue.popFirst() == 2.0)
        #expect(cube.calculateVolumeCallsCount == 2)
        #expect(cube.isVolumeCached)

        let accessVolume3 = cube.volume
        #expect(accessVolume3 == 2.0)
        #expect(baseAreaQueue.popFirst() == nil)
        #expect(cube.calculateBaseAreaCallsCount == 2)
        #expect(cube.isBaseAreaCached)
        #expect(volumeQueue.popFirst() == nil)
        #expect(cube.calculateVolumeCallsCount == 2)
        #expect(cube.isVolumeCached)

        cube.z = 3.0 // accessVolume4, accessBaseArea6
        #expect(baseAreaQueue.popFirst() == nil)
        #expect(cube.calculateBaseAreaCallsCount == 2)
        #expect(cube.isBaseAreaCached)
        #expect(volumeQueue.popFirst() == 6.0)
        #expect(cube.calculateVolumeCallsCount == 3)
        #expect(cube.isVolumeCached)

        volumeCancellable.cancel()
        #expect(volumeQueue.isEmpty)

        cube.y = 4.0 // accessBaseArea7
        #expect(baseAreaQueue.popFirst() == 8.0)
        #expect(cube.calculateBaseAreaCallsCount == 3)
        #expect(cube.isBaseAreaCached)
        #expect(cube.calculateVolumeCallsCount == 3)
        #expect(!cube.isVolumeCached)

        baseAreaCancellable.cancel()
        #expect(baseAreaQueue.isEmpty)

        cube.y = 5.0
        #expect(cube.calculateBaseAreaCallsCount == 3)
        #expect(!cube.isBaseAreaCached)
    }

    @Test
    func share() {
        let cube = Cube()
        var queue1 = [Double]()
        var queue2 = [Double]()

        // access1, access2
        let cancellable1 = cube.publisher.baseArea.sink { baseArea in
            queue1.append(baseArea)
        }
        let cancellable2 = cube.publisher.baseArea.sink { baseArea in
            queue2.append(baseArea)
        }

        #expect(queue1.popFirst() == 1.0)
        #expect(queue2.popFirst() == 1.0)
        #expect(cube.calculateBaseAreaCallsCount == 1)
        #expect(cube.isBaseAreaCached)

        cube.x = 2.0 // access3, access4
        #expect(queue1.popFirst() == 2.0)
        #expect(queue2.popFirst() == 2.0)
        #expect(cube.calculateBaseAreaCallsCount == 2)
        #expect(cube.isBaseAreaCached)

        cancellable1.cancel()
        #expect(queue1.isEmpty)

        cube.y = 3.0 // access5
        #expect(queue2.popFirst() == 6.0)
        #expect(cube.calculateBaseAreaCallsCount == 3)
        #expect(cube.isBaseAreaCached)

        cancellable2.cancel()
        #expect(queue2.isEmpty)
    }

}

extension PublishableMemoizedTests {

    @Publishable @Observable
    final class Cube {

        var offset = 0.0
        var x = 1.0
        var y = 1.0
        var z = 1.0

        @ObservationIgnored
        private(set) var calculateBaseAreaCallsCount = 0
        var isBaseAreaCached: Bool { _baseArea != nil }

        @ObservationIgnored
        private(set) var calculateVolumeCallsCount = 0
        var isVolumeCached: Bool { _volume != nil }

        @Memoized
        func calculateBaseArea() -> Double {
            calculateBaseAreaCallsCount += 1
            return x * y
        }

        @Memoized
        func calculateVolume() -> Double {
            calculateVolumeCallsCount += 1
            return baseArea * z
        }
    }
}
