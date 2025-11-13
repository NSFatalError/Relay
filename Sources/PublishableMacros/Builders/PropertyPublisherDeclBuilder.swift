//
//  PropertyPublisherDeclBuilder.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacros

internal struct PropertyPublisherDeclBuilder: ClassDeclBuilder {

    let declaration: ClassDeclSyntax
    let properties: PropertiesList
    let preferredGlobalActorIsolation: ExplicitGlobalActorIsolation?

    let accessControlLevelInheritanceSettings = AccessControlLevelInheritanceSettings(
        inheritingDeclaration: .member
    )

    func build() -> [DeclSyntax] { // swiftlint:disable:this type_contents_order
        [
            """
            \(inheritedAccessControlLevel)final class PropertyPublisher: AnyPropertyPublisher<\(trimmedType)> {

                \(deinitializer())

                \(storedPropertiesPublishers().formatted())

                \(computedPropertiesPublishers().formatted())
            }
            """
        ]
    }

    private func deinitializer() -> MemberBlockItemListSyntax {
        """
        deinit {
            \(storedPropertiesPublishersFinishCalls().formatted())
        }
        """
    }

    @CodeBlockItemListBuilder
    private func storedPropertiesPublishersFinishCalls() -> CodeBlockItemListSyntax {
        for property in properties.stored.mutable.instance {
            "_\(property.trimmedName).send(completion: .finished)"
        }
    }

    @MemberBlockItemListBuilder
    private func storedPropertiesPublishers() -> MemberBlockItemListSyntax {
        for property in properties.stored.mutable.instance {
            let globalActor = inheritedGlobalActorIsolation
            let accessControlLevel = property.declaration.inlinableAccessControlLevel(
                inheritedBy: .peer,
                maxAllowed: .public
            )
            let name = property.trimmedName
            let type = property.inferredType
            """
            fileprivate let _\(name) = PassthroughSubject<\(type), Never>()
            \(globalActor)\(accessControlLevel)var \(name): AnyPublisher<\(type), Never> {
                _storedPropertyPublisher(_\(name), for: \\.\(name))
            }
            """
        }
    }

    @MemberBlockItemListBuilder
    private func computedPropertiesPublishers() -> MemberBlockItemListSyntax {
        for property in properties.computed.instance {
            let globalActor = inheritedGlobalActorIsolation
            let accessControlLevel = property.declaration.inlinableAccessControlLevel(
                inheritedBy: .peer,
                maxAllowed: .public
            )
            let name = property.trimmedName
            let type = property.inferredType
            """
            \(globalActor)\(accessControlLevel)var \(name): AnyPublisher<\(type), Never> {
                _computedPropertyPublisher(for: \\.\(name))
            }
            """
        }
    }
}
