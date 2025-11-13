# Publishable

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNSFatalError%2FPublishable%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NSFatalError/Publishable)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNSFatalError%2FPublishable%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NSFatalError/Publishable)
[![Codecov](https://codecov.io/github/NSFatalError/Publishable/graph/badge.svg?token=axMe8BnuvB)](https://codecov.io/github/NSFatalError/Publishable)

Synchronous observation of `Observable` changes through `Combine`

#### Contents
- [What Problem Publishable Solves?](#what-problem-publishable-solves)
- [How Publishable Works?](#how-publishable-works)
- [Documentation](#documentation)
- [Installation](#installation)

## What Problem Publishable Solves?

With the introduction of [SE-0475: Transactional Observation of Values](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0475-observed.md),
Swift gains built-in support for observing changes to `Observable` types. This solution is great, but it only covers some of the use cases, as it 
publishes the updates via an `AsyncSequence`.

In some scenarios, however, developers need to perform actions synchronously - immediately after a change occurs.

This is where `Publishable` comes in. It allows `Observation` and `Combine` to coexist within a single type, letting you take advantage of the latest 
`Observable` features, while processing changes synchronously when needed. It integrates just as smoothly with the `SwiftData.Model` macro 
and can be extended to support other macros built on `Observation`.

```swift
import Publishable 

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

## How Publishable Works?

The `@Publishable` macro relies on two key properties of Swift Macros and `Observation` module:
- Macro expansions are compiled in the context of the module where they’re used. This allows references in the macro to be overloaded by locally available symbols.
- Swift exposes `ObservationRegistrar` as a documented, public API, making it possible to use it safely and directly.

`Publishable` leverages these facts to overload the default `ObservationRegistrar` with a custom one that:
- Forwards changes to Swift’s native `ObservationRegistrar`
- Simultaneously emits values through generated `Combine` publishers

While I acknowledge that this usage might not have been intended by the authors, I would refrain from calling it a hack.
It relies solely on well-understood behaviors of Swift and its public APIs.

This approach has been carefully tested and verified to work with both `Observable` and `SwiftData.Model` macros.

## Documentation

[Full documentation is available on the Swift Package Index.](https://swiftpackageindex.com/NSFatalError/Publishable/documentation/publishable)

## Installation

```swift
.package(
    url: "https://github.com/NSFatalError/Publishable",
    from: "1.0.0"
)
```
