//
//  ObservableDeclBuilder.swift
//  Relay
//
//  Created by Kamil Strzelecki on 28/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

internal struct ObservableDeclBuilder: ClassDeclBuilder, MemberBuilding {

    let declaration: ClassDeclSyntax
    private let genericParameter: TokenSyntax

    init(
        declaration: ClassDeclSyntax,
        context: some MacroExpansionContext
    ) {
        self.declaration = declaration
        self.genericParameter = context.makeUniqueName("T")
    }

    func build() -> [DeclSyntax] {
        [
            observationRegistrarProperty(),
            shouldNotifyObserversFunction(),
            shouldNotifyObserversEquatableFunction(),
            shouldNotifyObserversAnyObjectFunction(),
            shouldNotifyObserversAnyObjectEquatableFunction()
        ]
    }

    private func observationRegistrarProperty() -> DeclSyntax {
        "private let _$observationRegistrar = Observation.ObservationRegistrar()"
    }

    private func shouldNotifyObserversFunction() -> DeclSyntax {
        """
        private nonisolated func shouldNotifyObservers<\(genericParameter)>(
            _ lhs: \(genericParameter), 
            _ rhs: \(genericParameter)
        ) -> Bool { 
            true
        }
        """
    }

    private func shouldNotifyObserversEquatableFunction() -> DeclSyntax {
        """
        private nonisolated func shouldNotifyObservers<\(genericParameter): Equatable>(
            _ lhs: \(genericParameter), 
            _ rhs: \(genericParameter)
        ) -> Bool { 
            lhs != rhs
        }
        """
    }

    private func shouldNotifyObserversAnyObjectFunction() -> DeclSyntax {
        """
        private nonisolated func shouldNotifyObservers<\(genericParameter): AnyObject>(
            _ lhs: \(genericParameter), 
            _ rhs: \(genericParameter)
        ) -> Bool { 
            lhs !== rhs
        }
        """
    }

    private func shouldNotifyObserversAnyObjectEquatableFunction() -> DeclSyntax {
        """
        private nonisolated func shouldNotifyObservers<\(genericParameter): AnyObject & Equatable>(
            _ lhs: \(genericParameter), 
            _ rhs: \(genericParameter)
        ) -> Bool { 
            lhs != rhs
        }
        """
    }
}
