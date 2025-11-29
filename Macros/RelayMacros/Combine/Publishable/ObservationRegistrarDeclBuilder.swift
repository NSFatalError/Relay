//
//  ObservationRegistrarDeclBuilder.swift
//  Relay
//
//  Created by Kamil Strzelecki on 14/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

internal struct ObservationRegistrarDeclBuilder: ClassDeclBuilder, MemberBuilding {

    let declaration: ClassDeclSyntax
    let preferredGlobalActorIsolation: GlobalActorIsolation?
    private let trackedProperties: PropertiesList
    private let genericParameter: TokenSyntax

    init(
        declaration: ClassDeclSyntax,
        properties: PropertiesList,
        preferredGlobalActorIsolation: GlobalActorIsolation?,
        context: some MacroExpansionContext
    ) {
        self.declaration = declaration
        self.preferredGlobalActorIsolation = preferredGlobalActorIsolation
        self.trackedProperties = properties.filter(\.isStoredPublishable)
        self.genericParameter = context.makeUniqueName("T")
    }

    func build() -> [DeclSyntax] {
        [
            """
            private enum Observation {

                nonisolated struct ObservationRegistrar: PublishableObservationRegistrar {

                    private let underlying = SwiftObservationRegistrar()

                    \(publishFunction())

                    \(observationRegistrarWillSetDidSetAccessFunctions())

                    \(observationRegistrarWithMutationFunction())

                    \(assumeIsolatedIfNeededFunction())
                }
            }
            """
        ]
    }

    private func publishFunction() -> MemberBlockItemListSyntax {
        """
        \(inheritedGlobalActorIsolation)private func publish(
            _ object: \(trimmedType),
            keyPath: KeyPath<\(trimmedType), some Any>
        ) {
            \(publishKeyPathLookups().formatted())
        }
        """
    }

    @CodeBlockItemListBuilder
    private func publishKeyPathLookups() -> CodeBlockItemListSyntax {
        for property in trackedProperties {
            let lookup = publishKeyPathLookup(for: property)
            if let ifConfigLookup = property.underlying.applyingEnclosingIfConfig(to: lookup) {
                ifConfigLookup
            } else {
                lookup
            }
        }
    }

    private func publishKeyPathLookup(for property: Property) -> CodeBlockItemListSyntax {
        // Stored properties cannot be made potentially unavailable
        let name = property.trimmedName

        return """
        if keyPath == \\.\(name) {
            object.publisher._\(name).send(object[keyPath: \\.\(name)])
            return
        }
        """
    }

    private func observationRegistrarWillSetDidSetAccessFunctions() -> MemberBlockItemListSyntax {
        """
        nonisolated func willSet(
            _ object: \(trimmedType),
            keyPath: KeyPath<\(trimmedType), some Any>
        ) {
            nonisolated(unsafe) let keyPath = keyPath
            assumeIsolatedIfNeeded {
                object.publisher._beginModifications()
                underlying.willSet(object, keyPath: keyPath)
            }
        }

        nonisolated func didSet(
            _ object: \(trimmedType),
            keyPath: KeyPath<\(trimmedType), some Any>
        ) {
            nonisolated(unsafe) let keyPath = keyPath
            assumeIsolatedIfNeeded {
                underlying.didSet(object, keyPath: keyPath)
                publish(object, keyPath: keyPath)
                object.publisher._endModifications()
            }
        }

        nonisolated func access(
            _ object: \(trimmedType),
            keyPath: KeyPath<\(trimmedType), some Any>
        ) {
            underlying.access(object, keyPath: keyPath)
        }
        """
    }

    private func observationRegistrarWithMutationFunction() -> MemberBlockItemListSyntax {
        """
        nonisolated func withMutation<\(genericParameter)>(
            of object: \(trimmedType),
            keyPath: KeyPath<\(trimmedType), some Any>,
            _ mutation: () throws -> \(genericParameter)
        ) rethrows -> \(genericParameter) {
            nonisolated(unsafe) let mutation = mutation
            nonisolated(unsafe) let keyPath = keyPath
            nonisolated(unsafe) var result: \(genericParameter)!

            try assumeIsolatedIfNeeded {
                object.publisher._beginModifications()
                defer {
                    publish(object, keyPath: keyPath)
                    object.publisher._endModifications()
                }
                result = try underlying.withMutation(
                    of: object, 
                    keyPath: keyPath,
                    mutation
                )
            }

            return result
        }
        """
    }

    private func assumeIsolatedIfNeededFunction() -> MemberBlockItemListSyntax {
        if let globalActor = inheritedGlobalActorIsolation?.standardizedIsolationType {
            // https://github.com/swiftlang/swift/blob/main/stdlib/public/Concurrency/MainActor.swift
            """
            private nonisolated func assumeIsolatedIfNeeded(
                _ operation: @\(globalActor) () throws -> Void,
                file: StaticString = #fileID,
                line: UInt = #line
            ) rethrows {
                try withoutActuallyEscaping(operation) { operation in
                    typealias Nonisolated = () throws -> Void
                    let rawOperation = unsafeBitCast(operation, to: Nonisolated.self)

                    try \(globalActor).shared.assumeIsolated(
                        { _ in 
                            try rawOperation()
                        },
                        file: file,
                        line: line
                    )
                }
            }
            """
        } else {
            """
            private nonisolated func assumeIsolatedIfNeeded(
                _ operation: () throws -> Void
            ) rethrows {
                try operation()
            }
            """
        }
    }
}
