//
//  PublishableObservationRegistrar.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 18/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Observation

@_documentation(visibility: private)
public protocol PublishableObservationRegistrar {

    associatedtype Object: Publishable, Observable

    var underlying: SwiftObservationRegistrar { get }

    func publish(
        _ object: Object,
        keyPath: KeyPath<Object, some Any>
    )
}

extension PublishableObservationRegistrar {

    public func willSet(
        _ object: Object,
        keyPath: KeyPath<Object, some Any>
    ) {
        object.publisher.beginModifications()
        underlying.willSet(object, keyPath: keyPath)
    }

    public func didSet(
        _ object: Object,
        keyPath: KeyPath<Object, some Any>
    ) {
        underlying.didSet(object, keyPath: keyPath)
        publish(object, keyPath: keyPath)
        object.publisher.endModifications()
    }

    public func access(
        _ object: Object,
        keyPath: KeyPath<Object, some Any>
    ) {
        underlying.access(object, keyPath: keyPath)
    }

    public func withMutation<T>(
        of object: Object,
        keyPath: KeyPath<Object, some Any>,
        _ mutation: () throws -> T
    ) rethrows -> T {
        object.publisher.beginModifications()
        let result = try underlying.withMutation(of: object, keyPath: keyPath, mutation)
        publish(object, keyPath: keyPath)
        object.publisher.endModifications()
        return result
    }
}

@_documentation(visibility: private)
public protocol MainActorPublishableObservationRegistrar {

    associatedtype Object: Publishable, Observable

    var underlying: SwiftObservationRegistrar { get }

    @MainActor
    func publish(
        _ object: Object,
        keyPath: KeyPath<Object, some Any>
    )
}

extension MainActorPublishableObservationRegistrar {

    @MainActor
    public func willSet(
        _ object: Object,
        keyPath: KeyPath<Object, some Any>
    ) {
        object.publisher.beginModifications()
        underlying.willSet(object, keyPath: keyPath)
    }

  @MainActor
    public func didSet(
        _ object: Object,
        keyPath: KeyPath<Object, some Any>
    ) {
        underlying.didSet(object, keyPath: keyPath)
        publish(object, keyPath: keyPath)
        object.publisher.endModifications()
    }

    @MainActor
    public func access(
        _ object: Object,
        keyPath: KeyPath<Object, some Any>
    ) {
        underlying.access(object, keyPath: keyPath)
    }

    @MainActor
    public func withMutation<T>(
        of object: Object,
        keyPath: KeyPath<Object, some Any>,
        _ mutation: () throws -> T
    ) rethrows -> T {
        object.publisher.beginModifications()
        let result = try underlying.withMutation(of: object, keyPath: keyPath, mutation)
        publish(object, keyPath: keyPath)
        object.publisher.endModifications()
        return result
    }
}
