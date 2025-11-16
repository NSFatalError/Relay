# Relay

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNSFatalError%2FRelay%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NSFatalError/Relay)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNSFatalError%2FRelay%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NSFatalError/Relay)
[![Codecov](https://codecov.io/gh/NSFatalError/Relay/graph/badge.svg?token=axMe8BnuvB)](https://codecov.io/gh/NSFatalError/Relay)

Essential tools that extend the capabilities of `Observation`.

#### Contents
- [Publishable](#publishable)
- [Memoized](#memoized)
- [Documentation](#documentation)
- [Installation](#installation)

## Publishable

<details>
<summary> Observe changes to Observable types synchronously with Combine. </summary>
<br />

With the introduction of [Observations](https://developer.apple.com/documentation/observation/observations),
Swift gained built-in support for observing changes to `Observable` types. This solution is great, but it only covers some of the use cases, 
as it publishes the updates via an `AsyncSequence`.

In some scenarios, however, developers need to perform actions synchronously - immediately after a change occurs.

This is where `@Publishable` macro comes in. It allows `Observation` and `Combine` to coexist within a single type, letting you 
take advantage of the latest `Observable` features, while processing changes synchronously when needed. It integrates 
with both the `@Observable` and `@Model` macros and could be extended to support other macros built on top of `Observation`:

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

### How Publishable Works?

The `@Publishable` macro relies on two key properties of Swift Macros and `Observation` module:
- Macro expansions are compiled in the context of the module where they’re used. This allows references in the macro to be overloaded by locally available symbols.
- Swift exposes `ObservationRegistrar` as a documented, public API, making it possible to use it safely and directly.

By leveraging these facts, the `@Publishable` macro can overload the default `ObservationRegistrar` with a custom one that:
- Forwards changes to Swift’s native `ObservationRegistrar`
- Simultaneously emits values through generated `Combine` publishers

While I acknowledge that this usage might not have been intended by the authors, I would refrain from calling it a hack.
It relies solely on well-understood behaviors of Swift and its public APIs.

This approach has been carefully tested and verified to work with both `@Observable` and `@Model` macros.

</details>

## Memoized

<details>
<summary> Perform expensive computations lazily and cache their outputs until Observable inputs change. </summary>


Computed properties in Swift are a great way of getting an always-up-to-date values derived from other properties of a type.
However, they can also hide away computational complexity from the caller, who might assume that accessing them is trivial 
and therefore call them repeatedly.

With the conveniences afforded by `SwiftUI` and `Observation`, it’s easy to fall into this trap by performing expensive computations,
like mapping or filtering a collection, every time `View.body` is accessed:

```swift
@MainActor @Observable
final class ViewModel {
    var data = [String]()
    var query: String?

    var filteredData: [String] {
        print("recompute")
        guard let query else {
            return data
        }
        return data.filter { 
            $0.localizedCaseInsensitiveContains(query)
        }
    }
}

let model = ViewModel()
model.filteredData // Prints: recompute
model.filteredData // Prints: recompute

model.data = [...]
model.filteredData // Prints: recompute
model.filteredData // Prints: recompute

model.data = [...]
model.query = "..."
model.filteredData // Prints: recompute
model.filteredData // Prints: recompute
```

In the example above, it’s clear that we could save computing resources on repeated access to `filteredData`
when both `query` and `data` remain unchanged. The `@Memoized` macro allows you to do exactly that 
by automatically caching and updating values derived from their underlying `Observable` inputs.

To use it, refactor your computed property into a method and apply the `@Memoized` macro to it:

```swift
@MainActor @Observable
final class ViewModel {
    var data = [String]()
    var query: String?

    @Memoized("filteredData")
    private func filterData() -> [String] {
        print("recompute")
        guard let query else {
            return data
        }
        return data.filter { 
            $0.localizedCaseInsensitiveContains(query)
        }
    }
}

let model = ViewModel()
model.filteredData // Prints: recompute
model.filteredData

model.data = [...]
model.filteredData // Prints: recompute
model.filteredData

model.data = [...]
model.query = "..."
model.filteredData // Prints: recompute
model.filteredData
```

</details>

## Documentation

[Full documentation is available on the Swift Package Index.](https://swiftpackageindex.com/NSFatalError/Relay/documentation/relay)

## Installation

```swift
.package(
    url: "https://github.com/NSFatalError/Relay",
    from: "1.0.0"
)
```
