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
            \(storedPropertiesSubjectsFinishCalls().formatted())
        }
        """
    }

    @CodeBlockItemListBuilder
    private func storedPropertiesSubjectsFinishCalls() -> CodeBlockItemListSyntax {
        for property in properties.all where property.isStoredPublishable {
            let call = storedPropertySubjectFinishCall(for: property)
            if let ifConfigCall = property.underlying.applyingEnclosingIfConfig(to: call) {
                ifConfigCall
            } else {
                call
            }
        }
    }

    private func storedPropertySubjectFinishCall(for property: Property) -> CodeBlockItemListSyntax {
        "_\(property.trimmedName).send(completion: .finished)"
    }

    @MemberBlockItemListBuilder
    private func storedPropertiesPublishers() -> MemberBlockItemListSyntax {
        for property in properties.all where property.isStoredPublishable {
            let publisher = storedPropertyPublisher(for: property)
            if let ifConfigPublisher = property.underlying.applyingEnclosingIfConfig(to: publisher) {
                ifConfigPublisher
            } else {
                publisher
            }
        }
    }

    private func storedPropertyPublisher(for property: Property) -> MemberBlockItemListSyntax {
        // Stored properties cannot be made potentially unavailable
        let accessControlLevel = AccessControlLevel.forSibling(of: property.underlying)
        let name = property.trimmedName
        let type = property.inferredType

        return """
        fileprivate final let _\(name) = PassthroughSubject<\(type), Never>()
        \(accessControlLevel)final var \(name): some Publisher<\(type), Never> {
            _storedPropertyPublisher(_\(name), for: \\.\(name), object: object)
        }
        """
    }

    @MemberBlockItemListBuilder
    private func computedPropertiesPublishers() -> MemberBlockItemListSyntax {
        for property in properties.all where property.isComputedPublishable {
            let publisher = computedPropertyPublisher(for: property)
            if let ifConfigPublisher = property.underlying.applyingEnclosingIfConfig(to: publisher) {
                ifConfigPublisher
            } else {
                publisher
            }
        }
    }

    private func computedPropertyPublisher(for property: Property) -> MemberBlockItemListSyntax {
        let accessControlLevel = AccessControlLevel.forSibling(of: property.underlying)
        let availability = property.availability?.trimmed.withTrailingNewline
        let name = property.trimmedName
        let type = property.inferredType

        return """
        \(availability)\(accessControlLevel)final var \(name): some Publisher<\(type), Never> {
            _computedPropertyPublisher(for: \\.\(name), object: object)
        }
        """
    }

    @MemberBlockItemListBuilder
    private func memoizedPropertiesPublishers() -> MemberBlockItemListSyntax {
        for member in declaration.memberBlock.members {
            if let extractionResult = MemoizedMacro.extract(from: member.decl) {
                let declaration = extractionResult.declaration

                if !declaration.attributes.contains(like: PublisherIgnoredMacro.attribute) {
                    let publisher = memoizedPropertyPublisher(for: extractionResult)
                    if let ifConfigPublisher = declaration.applyingEnclosingIfConfig(to: publisher) {
                        ifConfigPublisher
                    } else {
                        publisher
                    }
                }
            }
        }
    }

    private func memoizedPropertyPublisher(
        for extractionResult: MemoizedMacro.ExtractionResult
    ) -> MemberBlockItemListSyntax {
        let accessControlLevel = extractionResult.preferredAccessControlLevel?.inheritedBySibling()
        let availability = extractionResult.declaration.availability?.trimmed.withTrailingNewline
        let name = extractionResult.propertyName
        let type = extractionResult.trimmedReturnType

        return """
        \(availability)\(accessControlLevel)final var \(raw: name): some Publisher<\(type), Never> {
            _computedPropertyPublisher(for: \\.\(raw: name), object: object)
        }
        """
    }
}
