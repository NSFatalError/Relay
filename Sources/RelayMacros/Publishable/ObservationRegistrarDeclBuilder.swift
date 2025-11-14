//
//  ObservationRegistrarDeclBuilder.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 14/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacros

internal struct ObservationRegistrarDeclBuilder: ClassDeclBuilder, MemberBuilding {

    let declaration: ClassDeclSyntax
    let properties: PropertiesList
    let preferredGlobalActorIsolation: GlobalActorIsolation?

    private var registeredProperties: PropertiesList {
        properties.stored.mutable.instance
    }

    func build() -> [DeclSyntax] {
        [
            """
            private enum Observation {

                struct ObservationRegistrar: \(inheritedGlobalActorIsolation)PublishableObservationRegistrar {

                    private let underlying = SwiftObservationRegistrar()

                    \(publishNewValueFunction())

                    \(subjectFunctions().formatted())

                    \(publishableObservationRegistrarFunctions())

                    \(assumeIsolatedIfNeededFunction())
                }
            }
            """
        ]
    }

    private func publishNewValueFunction() -> MemberBlockItemListSyntax {
        """
        \(inheritedGlobalActorIsolation)func publish(
            _ object: \(trimmedType),
            keyPath: KeyPath<\(trimmedType), some Any>
        ) {
            \(publishNewValueKeyPathCasting().formatted())
        }
        """
    }

    @CodeBlockItemListBuilder
    private func publishNewValueKeyPathCasting() -> CodeBlockItemListSyntax {
        for inferredType in registeredProperties.uniqueInferredTypes {
            """
            if let keyPath = keyPath as? KeyPath<\(trimmedType), \(inferredType)>,
               let subject = subject(for: keyPath, on: object) {
                subject.send(object[keyPath: keyPath])
                return
            }
            """
        }
        """
        assertionFailure("Unknown keyPath: \\(keyPath)")
        """
    }

    @MemberBlockItemListBuilder
    private func subjectFunctions() -> MemberBlockItemListSyntax {
        for inferredType in registeredProperties.uniqueInferredTypes {
            """
            \(inheritedGlobalActorIsolation)private func subject(
                for keyPath: KeyPath<\(trimmedType), \(inferredType)>,
                on object: \(trimmedType)
            ) -> PassthroughSubject<\(inferredType), Never>? {
                \(subjectKeyPathCasting(for: inferredType).formatted())
            }
            """
        }
    }

    @CodeBlockItemListBuilder
    private func subjectKeyPathCasting(for inferredType: TypeSyntax) -> CodeBlockItemListSyntax {
        for property in registeredProperties.withInferredType(like: inferredType) {
            let name = property.trimmedName
            """
            if keyPath == \\.\(name) {
                return object.publisher._\(name)
            }
            """
        }
        """
        return nil
        """
    }

    private func publishableObservationRegistrarFunctions() -> MemberBlockItemListSyntax {
        """
        nonisolated func willSet(
            _ object: \(trimmedType),
            keyPath: KeyPath<\(trimmedType), some Any>
        ) {
            nonisolated(unsafe) let keyPath = keyPath
            assumeIsolatedIfNeeded {
                object.publisher.beginModifications()
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
                object.publisher.endModifications()
            }
        }

        nonisolated func access(
            _ object: \(trimmedType),
            keyPath: KeyPath<\(trimmedType), some Any>
        ) {
            underlying.access(object, keyPath: keyPath)
        }

        nonisolated func withMutation<T>(
            of object: \(trimmedType),
            keyPath: KeyPath<\(trimmedType), some Any>,
            _ mutation: () throws -> T
        ) rethrows -> T {
            nonisolated(unsafe) let mutation = mutation
            nonisolated(unsafe) let keyPath = keyPath
            nonisolated(unsafe) var result: T!

            try assumeIsolatedIfNeeded {
                object.publisher.beginModifications()
                result = try underlying.withMutation(of: object, keyPath: keyPath, mutation)
                publish(object, keyPath: keyPath)
                object.publisher.endModifications()
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
