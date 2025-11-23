//
//  PropertyPublisherDeclBuilder.swift
//  Relay
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

internal struct PropertyPublisherDeclBuilder: ClassDeclBuilder, MemberBuilding {

    let declaration: ClassDeclSyntax
    let properties: PropertiesList
    let trimmedSuperclassType: TypeSyntax?
    let preferredGlobalActorIsolation: GlobalActorIsolation?

    func build() -> [DeclSyntax] {
        [
            """
            \(inheritedGlobalActorIsolation)\(inheritedAccessControlLevelAllowingOpen)\(inheritedFinalModifier)\
            class PropertyPublisher: \(inheritanceClause()) {
            
                private final unowned let object: \(trimmedType)
            
                \(objectWillChangeDidChangePublishers())
            
                \(initializer())

                \(deinitializer())

                \(storedPropertiesPublishers().formatted())

                \(computedPropertiesPublishers().formatted())

                \(memoizedPropertiesPublishers().formatted())
            }
            """
        ]
    }

    private func inheritanceClause() -> TypeSyntax {
        if let trimmedSuperclassType {
            "\(trimmedSuperclassType).PropertyPublisher"
        } else {
            "Relay.AnyPropertyPublisher"
        }
    }

    private func objectWillChangeDidChangePublishers() -> MemberBlockItemListSyntax {
        let notation = CamelCaseNotation(string: trimmedType.description)
        let prefix = notation.joined(as: .lowerCamelCase)

        return """
        \(inheritedAccessControlLevel)final var \
        \(raw: prefix)WillChange: some Publisher<\(trimmedType), Never> {
            willChange.map { [unowned object] _ in
                object 
            }
        }
        
        \(inheritedAccessControlLevel)final var \
        \(raw: prefix)DidChange: some Publisher<\(trimmedType), Never> {
            didChange.map { [unowned object] _ in
                object 
            }
        }
        """
    }

    private func initializer() -> MemberBlockItemListSyntax {
        """
        \(inheritedAccessControlLevel)init(object: \(trimmedType)) {
            self.object = object
            super.init(object: object)
        }
        """
    }

    private func deinitializer() -> MemberBlockItemListSyntax {
        """
        \(inheritedGlobalActorIsolation)deinit {
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
            let accessControlLevel = AccessControlLevel.forSibling(of: property.underlying)
            let name = property.trimmedName
            let type = property.inferredType
            """
            fileprivate final let _\(name) = PassthroughSubject<\(type), Never>()
            \(accessControlLevel)final var \(name): some Publisher<\(type), Never> {
                _storedPropertyPublisher(_\(name), for: \\.\(name), object: object)
            }
            """
        }
    }

    @MemberBlockItemListBuilder
    private func computedPropertiesPublishers() -> MemberBlockItemListSyntax {
        for property in properties.computed.instance.all {
            let accessControlLevel = AccessControlLevel.forSibling(of: property.underlying)
            let name = property.trimmedName
            let type = property.inferredType
            """
            \(accessControlLevel)final var \(name): some Publisher<\(type), Never> {
                _computedPropertyPublisher(for: \\.\(name), object: object)
            }
            """
        }
    }

    @MemberBlockItemListBuilder
    private func memoizedPropertiesPublishers() -> MemberBlockItemListSyntax {
        for member in declaration.memberBlock.members {
            if let functionDecl = member.decl.as(FunctionDeclSyntax.self),
               let attribute = functionDecl.attributes.first(like: MemoizedMacro.attribute),
               let parameters = try? MemoizedMacro.Parameters(from: attribute),
               let trimmedReturnType = MemoizedMacro.trimmedReturnType(of: functionDecl) {
                let globalActor = parameters.preferredGlobalActorIsolation
                let accessControlLevel = parameters.preferredAccessControlLevel?.inheritedBySibling()
                let name = parameters.preferredPropertyName ?? MemoizedMacro.defaultPropertyName(for: functionDecl)
                let type = trimmedReturnType
                """
                \(globalActor)\(accessControlLevel)final var \(raw: name): some Publisher<\(type), Never> {
                    _computedPropertyPublisher(for: \\.\(raw: name), object: object)
                }
                """
            }
        }
    }
}
