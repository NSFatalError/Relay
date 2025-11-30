# How Publishable Works?

Learn how the ``Publishable()`` macro works under the hood.

The ``Publishable()`` macro relies on two key properties of Swift Macros and `Observation` module:
- Macro expansions are compiled in the context of the module where they’re used. This allows references in the macro to be overloaded by locally available symbols.
- Swift exposes `ObservationRegistrar` as a documented, public API, making it possible to use it safely and directly.

By leveraging these facts, the ``Publishable()`` macro can overload the default `ObservationRegistrar` with a custom one that:
- Forwards changes to Swift’s native `ObservationRegistrar`
- Simultaneously emits values through generated `Combine` publishers

While I acknowledge that this usage might not have been intended by the authors, I would refrain from calling it a hack.
It relies solely on well-understood behaviors of Swift and its public APIs.

This approach has been carefully tested and verified to work with the `@Observable` macro.
