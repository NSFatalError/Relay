# Combine

Observe changes to `Observable` types synchronously with `Combine`.

## Overview

With the introduction of [Observations](https://developer.apple.com/documentation/observation/observations),
Swift gained built-in support for observing changes to `Observable` types. This solution is great, but it only covers some of the use cases, 
as it publishes the updates via an `AsyncSequence`.

In some scenarios, however, developers need to perform actions synchronously - immediately after a change occurs.

This is where the ``Publishable()`` macro comes in. It allows `Observation` and `Combine` to coexist within a single type, letting you 
take advantage of the latest `Observable` features while processing changes synchronously when needed. It integrates with the `@Observable` 
macro and is designed to be compatible with other macros built on top of `Observation`:

```swift
import Relay 

@Publishable @Observable
final class Person {
    var name = "John"
    var surname = "Doe"

    var fullName: String {
        "\(name) \(surname)"
    }
}

let person = Person()
let nameCancellable = person.publisher.name.sink { name in
    print("Name -", name)
}
let fullNameCancellable = person.publisher.fullName.sink { fullName in
    print("Full name -", fullName)
}

// Initially prints (same as `Published` property wrapper):
// Name - John
// Full name - John Doe

person.name = "Kamil"
// Prints:
// Name - Kamil
// Full name - Kamil Doe

person.surname = "Strzelecki"
// Prints:
// Full name - Kamil Strzelecki
```

## Topics

### Making Types Publishable

- <doc:ChoosingBetweenRelayedAndPublished>
- ``Relayed()``
- ``Relayed(isolation:)``
- ``Publishable()``
- ``Publishable(isolation:)``

### Customizing Generated Declarations

- ``ObservationSuppressed()``
- ``PublisherSuppressed()``

### Observing Changes with Combine

- ``Publishable-protocol``
- ``AnyPropertyPublisher``
