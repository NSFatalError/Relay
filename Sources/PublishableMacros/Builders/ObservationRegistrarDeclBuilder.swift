//
//  ObservationRegistrarDeclBuilder.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 14/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacros

internal struct ObservationRegistrarDeclBuilder: ClassDeclBuilder {

    let declaration: ClassDeclSyntax
    let properties: PropertiesList
    let mainActor: Bool

    var settings: DeclBuilderSettings {
        .init(accessControlLevel: .init(inheritingDeclaration: .member))
    }

    private var registeredProperties: PropertiesList {
        properties.stored.mutable.instance
    }

    func build() -> [DeclSyntax] {
        if mainActor {
            return [
                """
                private enum Observation {

                    @MainActor
                    struct ObservationRegistrar: PublishableObservationRegistrar {

                        let underlying = SwiftObservationRegistrar()

                        \(publishNewValueFunction())

                        \(subjectFunctions().formatted())
                    }
                }
                """
            ]
        } else {
            return [
                """
                private enum Observation {

                    struct ObservationRegistrar: PublishableObservationRegistrar {

                        let underlying = SwiftObservationRegistrar()

                        \(publishNewValueFunction())

                        \(subjectFunctions().formatted())
                    }
                }
                """
            ]
        }
    }

    private func publishNewValueFunction() -> MemberBlockItemListSyntax {
        """
        func publish(
            _ object: \(trimmedTypeName),
            keyPath: KeyPath<\(trimmedTypeName), some Any>
        ) {
            \(publishNewValueKeyPathCasting().formatted())
        }
        """
    }

    @CodeBlockItemListBuilder
    private func publishNewValueKeyPathCasting() -> CodeBlockItemListSyntax {
        for inferredType in registeredProperties.uniqueInferredTypes {
            """
            if let keyPath = keyPath as? KeyPath<\(trimmedTypeName), \(inferredType)>,
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
            private func subject(
                for keyPath: KeyPath<\(trimmedTypeName), \(inferredType)>,
                on object: \(trimmedTypeName)
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
}
