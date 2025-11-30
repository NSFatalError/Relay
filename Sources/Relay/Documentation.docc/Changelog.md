# Changelog

Summary of breaking changes between major releases.

## Version 3.0

- ``AnyPropertyPublisher`` is no longer generic in order to allow subclassing of ``Publishable-protocol`` types. 
In consequence, its ``AnyPropertyPublisher/willChange`` and ``AnyPropertyPublisher/didChange`` publishers changed their output type 
from the specialized `Object` type to `Void`. Generated ``AnyPropertyPublisher`` subclasses still expose specialized publishers
with class names as their prefix, so an example class named `Person` will expose `personWillChange` and `personDidChange` publishers.
- Calling `@Model` macro compatible with `@Publishable` was unfortunately premature. SwiftData uses reflection to find property named
`_$observationRegistrar` and asserts if it cannot cast it to the default `ObservationRegistrar` type. Although its possible to circumvent 
this assertion, for example by making `Publishable` types conform to `CustomReflectable`, internals of the framework won't be able to send values
through the generated publishers. Thus, `@Publishable` macro now emits a warning when applied to `@Model` classes.

## Version 2.0

- `swift-tools-version` changed from 6.1 to 6.2.
