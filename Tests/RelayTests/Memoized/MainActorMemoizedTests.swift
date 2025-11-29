//
//  MainActorMemoizedTests.swift
//  Relay
//
//  Created by Kamil Strzelecki on 15/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Relay
import Testing

internal enum MainActorMemoizedTests {

    @MainActor
    struct Independent {

        @Test
        func access() {
            let cube = Cube()
            #expect(cube.calculateBaseAreaCallsCount == 0)
            #expect(!cube.isBaseAreaCached)

            cube.x = 2.0
            #expect(cube.calculateBaseAreaCallsCount == 0)
            #expect(!cube.isBaseAreaCached)

            let access1 = cube.baseArea
            #expect(access1 == 2.0)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(cube.isBaseAreaCached)

            let access2 = cube.baseArea
            #expect(access2 == 2.0)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(cube.isBaseAreaCached)

            cube.y = 3.0
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(!cube.isBaseAreaCached)

            let access3 = cube.baseArea
            #expect(access3 == 6.0)
            #expect(cube.calculateBaseAreaCallsCount == 2)
            #expect(cube.isBaseAreaCached)

            cube.offset = 100.0
            #expect(cube.calculateBaseAreaCallsCount == 2)
            #expect(cube.isBaseAreaCached)
        }

        @Test
        func trackWhenCached() {
            let cube = Cube()
            nonisolated(unsafe) var queue = [Bool]()

            func observe() {
                withObservationTracking {
                    _ = cube.baseArea
                } onChange: {
                    queue.append(true)
                }
            }

            let access1 = cube.baseArea
            #expect(access1 == 1.0)
            #expect(queue.popFirst() == nil)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(cube.isBaseAreaCached)

            observe() // access2
            #expect(queue.popFirst() == nil)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(cube.isBaseAreaCached)

            cube.x = 2.0
            #expect(queue.popFirst() == true)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(!cube.isBaseAreaCached)
        }

        @Test
        func trackWhenNotCached() {
            let cube = Cube()
            nonisolated(unsafe) var queue = [Bool]()

            func observe() {
                withObservationTracking {
                    _ = cube.baseArea
                } onChange: {
                    queue.append(true)
                }
            }

            observe() // access1
            #expect(queue.popFirst() == nil)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(cube.isBaseAreaCached)

            let access2 = cube.baseArea
            #expect(access2 == 1.0)
            #expect(queue.popFirst() == nil)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(cube.isBaseAreaCached)

            cube.x = 2.0
            #expect(queue.popFirst() == true)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(!cube.isBaseAreaCached)
        }
    }
}

extension MainActorMemoizedTests {

    @MainActor
    struct Dependent {

        @Test
        func access() {
            let cube = Cube()
            let accessVolume1 = cube.volume // accessBaseArea1
            #expect(accessVolume1 == 1.0)
            #expect(cube.calculateVolumeCallsCount == 1)
            #expect(cube.isVolumeCached)

            let accessBaseArea2 = cube.baseArea
            #expect(accessBaseArea2 == 1.0)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(cube.isBaseAreaCached)

            cube.x = 2.0
            #expect(cube.calculateVolumeCallsCount == 1)
            #expect(!cube.isVolumeCached)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(!cube.isBaseAreaCached)

            let accessBaseArea3 = cube.baseArea
            #expect(accessBaseArea3 == 2.0)
            #expect(cube.calculateBaseAreaCallsCount == 2)
            #expect(cube.isBaseAreaCached)

            let accessVolume2 = cube.volume // accessBaseArea4
            #expect(accessVolume2 == 2.0)
            #expect(cube.calculateVolumeCallsCount == 2)
            #expect(cube.isVolumeCached)

            cube.z = 3.0
            #expect(cube.calculateVolumeCallsCount == 2)
            #expect(!cube.isVolumeCached)
            #expect(cube.calculateBaseAreaCallsCount == 2)
            #expect(cube.isBaseAreaCached)

            let accessVolume3 = cube.volume // accessBaseArea5
            #expect(accessVolume3 == 6.0)
            #expect(cube.calculateVolumeCallsCount == 3)
            #expect(cube.isVolumeCached)
        }

        @Test
        func trackWhenCached() {
            let cube = Cube()
            nonisolated(unsafe) var queue = [Bool]()

            func observe() {
                withObservationTracking {
                    _ = cube.volume
                } onChange: {
                    queue.append(true)
                }
            }

            let access1 = cube.volume
            #expect(access1 == 1.0)
            #expect(queue.popFirst() == nil)
            #expect(cube.calculateVolumeCallsCount == 1)
            #expect(cube.isVolumeCached)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(cube.isBaseAreaCached)

            observe() // access2
            #expect(queue.popFirst() == nil)
            #expect(cube.calculateVolumeCallsCount == 1)
            #expect(cube.isVolumeCached)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(cube.isBaseAreaCached)

            cube.z = 2.0
            #expect(queue.popFirst() == true)
            #expect(cube.calculateVolumeCallsCount == 1)
            #expect(!cube.isVolumeCached)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(cube.isBaseAreaCached)
        }

        @Test
        func trackWhenNotCached() {
            let cube = Cube()
            nonisolated(unsafe) var queue = [Bool]()

            func observe() {
                withObservationTracking {
                    _ = cube.volume
                } onChange: {
                    queue.append(true)
                }
            }

            observe() // access1
            #expect(queue.popFirst() == nil)
            #expect(cube.calculateVolumeCallsCount == 1)
            #expect(cube.isVolumeCached)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(cube.isBaseAreaCached)

            let access2 = cube.volume
            #expect(access2 == 1.0)
            #expect(queue.popFirst() == nil)
            #expect(cube.calculateVolumeCallsCount == 1)
            #expect(cube.isVolumeCached)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(cube.isBaseAreaCached)

            cube.z = 2.0
            #expect(queue.popFirst() == true)
            #expect(cube.calculateVolumeCallsCount == 1)
            #expect(!cube.isVolumeCached)
            #expect(cube.calculateBaseAreaCallsCount == 1)
            #expect(cube.isBaseAreaCached)
        }
    }
}

extension MainActorMemoizedTests {

    @MainActor @Observable
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

        @Memoized(.fileprivate, "volume")
        func calculateVolume() -> Double {
            calculateVolumeCallsCount += 1
            return baseArea * z
        }

        #if os(macOS)
            @available(macOS 26, *) @Memoized
            func calculateConditionalValue() -> Double {
                volume
            }
        #endif
    }
}
