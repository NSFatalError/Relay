//
//  _Observable.swift
//  Relay
//
//  Created by Kamil Strzelecki on 01/12/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import Observation

@attached(
    member,
    names: named(_$observationRegistrar),
    named(access),
    named(withMutation),
    named(shouldNotifyObservers)
)
@attached(
    extension,
    conformances: Observable
)
@attached(
    memberAttribute
)
macro _Observable() = #externalMacro(
    module: "ObservationMacros",
    type: "ObservableMacro"
)
