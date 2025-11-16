# Memoized

Perform expensive computations lazily and cache their outputs until `Observable` inputs change.

## Overview

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
when both `query` and `data` remain unchanged. The ``Memoized(_:_:)`` macro allows you to do exactly that 
by automatically caching and updating values derived from their underlying `Observable` inputs.

To use it, refactor your computed property into a method and apply the ``Memoized(_:_:)`` macro to it.
The call site remains the same:

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

## Topics

### Memoizing Function Outputs

- ``Memoized(_:_:)``
- ``Memoized(_:_:isolation:)``
