//
//  PropertyPublisherDeclBuilder.swift
//  Relay
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxBuilder
import SwiftSyntaxMacros

internal struct PropertyPublisherDeclBuilder: ClassDeclBuilder, MemberBuilding {

    let declaration: ClassDeclSyntax
    let properties: PropertiesList
    let preferredGlobalActorIsolation: GlobalActorIsolation?

    func build() -> [DeclSyntax] {
        [
            """
            \(inheritedAccessControlLevel)final class PropertyPublisher: AnyPropertyPublisher<\(trimmedType)> {

                \(deinitializer())

                \(storedPropertiesPublishers().formatted())

                \(computedPropertiesPublishers().formatted())

                \(memoizedPropertiesPublishers().formatted())
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
        for property in properties.stored.mutable.instance.all {
            "_\(property.trimmedName).send(completion: .finished)"
        }
    }

    @MemberBlockItemListBuilder
    private func storedPropertiesPublishers() -> MemberBlockItemListSyntax {
        for property in properties.stored.mutable.instance.all {
            let globalActor = inheritedGlobalActorIsolation
            let accessControlLevel = AccessControlLevel.forSibling(of: property.underlying)
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
        for property in properties.computed.instance.all {
            let globalActor = inheritedGlobalActorIsolation
            let accessControlLevel = AccessControlLevel.forSibling(of: property.underlying)
            let name = property.trimmedName
            let type = property.inferredType
            """
            \(globalActor)\(accessControlLevel)var \(name): AnyPublisher<\(type), Never> {
                _computedPropertyPublisher(for: \\.\(name))
            }
            """
        }
    }

    @MemberBlockItemListBuilder
    private func memoizedPropertiesPublishers() -> MemberBlockItemListSyntax {
        for member in declaration.memberBlock.members {
            if let functionDecl = member.decl.as(FunctionDeclSyntax.self),
               let attribute = functionDecl.attributes.first(like: "@Memoized"),
               let parameters = try? MemoizedMacro.Parameters(from: attribute),
               let trimmedReturnType = MemoizedMacro.trimmedReturnType(of: functionDecl) {
                let globalActor = parameters.preferredGlobalActorIsolation ?? inheritedGlobalActorIsolation
                let accessControlLevel = parameters.preferredAccessControlLevel
                let name = parameters.preferredPropertyName ?? MemoizedMacro.defaultPropertyName(for: functionDecl)
                let type = trimmedReturnType
                """
                \(globalActor)\(accessControlLevel)var \(raw: name): AnyPublisher<\(type), Never> {
                    _computedPropertyPublisher(for: \\.\(raw: name))
                }
                """
            }
        }
    }
}
