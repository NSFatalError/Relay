# Changelog

Summary of breaking changes between major releases.

## Version 3.0

- All generated publishers now return an opaque `some Publisher<Output, Never>` type 
instead of an erased `AnyPublisher<Output, Never>`.

- When the ``Publishable()`` macro is used alongside the `@Observable` macro, a warning will be emitted 
suggesting a switch to the ``Relayed()`` macro instead.

- ``AnyPropertyPublisher`` is no longer generic, allowing subclassing of ``Publishable`` types.
As a consequence, its ``AnyPropertyPublisher/willChange`` and ``AnyPropertyPublisher/didChange`` publishers now output `Void`
instead of the specialized `Object` type. Generated subclasses still expose specialized publishers using the class name as a prefix.
For example, a class named `Person` will provide `personWillChange` and `personDidChange` publishers.

- Calling the `@Model` macro compatible with ``Publishable()`` turned out to be premature. `SwiftData` uses reflection
to find property named `_$observationRegistrar` and asserts if it cannot cast it to the default `ObservationRegistrar` type.
Although it's technically possible to bypass this assertion (for example, by making ``Publishable`` types conform to `CustomReflectable`),
the framework internals would still fail to send values through the generated publishers. Therefore, the ``Publishable()`` macro
now emits a warning when applied to `@Model` classes.

## Version 2.0

- Renamed library from `Publishable` to `Relay`.
- `swift-tools-version` changed from 6.1 to 6.2.
