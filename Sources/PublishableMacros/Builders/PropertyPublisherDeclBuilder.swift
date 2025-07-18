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
    let mainActor: Bool

    var settings: DeclBuilderSettings {
        .init(accessControlLevel: .init(inheritingDeclaration: .member))
    }

    func build() -> [DeclSyntax] {
        if mainActor {
            [
                """
                @MainActor
                \(inheritedAccessControlLevel)final class PropertyPublisher: AnyPropertyPublisher<\(trimmedTypeName)> {

                    \(deinitializer())

                    \(storedPropertiesPublishers().formatted())

                    \(computedPropertiesPublishers().formatted())
                }
                """
            ]
        } else {
            [
                """
                \(inheritedAccessControlLevel)final class PropertyPublisher: AnyPropertyPublisher<\(trimmedTypeName)> {

                    \(deinitializer())

                    \(storedPropertiesPublishers().formatted())

                    \(computedPropertiesPublishers().formatted())
                }
                """
            ]
        }
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
            let accessControlLevel = property.declaration.accessControlLevel(inheritedBy: .peer, maxAllowed: .public)
            let name = property.trimmedName
            let type = property.inferredType
            """
            fileprivate let _\(name) = PassthroughSubject<\(type), Never>()
            \(accessControlLevel)var \(name): AnyPublisher<\(type), Never> {
                _storedPropertyPublisher(_\(name), for: \\.\(name))
            }
            """
        }
    }

    @MemberBlockItemListBuilder
    private func computedPropertiesPublishers() -> MemberBlockItemListSyntax {
        for property in properties.computed.instance {
            let accessControlLevel = property.declaration.accessControlLevel(inheritedBy: .peer, maxAllowed: .public)
            let name = property.trimmedName
            let type = property.inferredType
            """
            \(accessControlLevel)var \(name): AnyPublisher<\(type), Never> {
                _computedPropertyPublisher(for: \\.\(name))
            }
            """
        }
    }
}
