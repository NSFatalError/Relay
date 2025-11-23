//
//  PublishableObservationRegistrar.swift
//  Relay
//
//  Created by Kamil Strzelecki on 18/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Observation

@_documentation(visibility: private)
public protocol PublishableObservationRegistrar {

    associatedtype Object: Publishable, Observable

    init()

    func willSet(
        _ object: Object,
        keyPath: KeyPath<Object, some Any>
    )

    func didSet(
        _ object: Object,
        keyPath: KeyPath<Object, some Any>
    )

    func access(
        _ object: Object,
        keyPath: KeyPath<Object, some Any>
    )

    func withMutation<T>(
        of object: Object,
        keyPath: KeyPath<Object, some Any>,
        _ mutation: () throws -> T
    ) rethrows -> T
}
