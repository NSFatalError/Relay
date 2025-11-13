//
//  PublisherDeclBuilder.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import PrincipleMacros

internal struct PublisherDeclBuilder: ClassDeclBuilder {

    let declaration: ClassDeclSyntax
    let properties: PropertiesList

    let accessControlLevelInheritanceSettings = AccessControlLevelInheritanceSettings(
        inheritingDeclaration: .member
    )

    func build() -> [DeclSyntax] {
        [
            """
            /// A ``PropertyPublisher`` which exposes `Combine` publishers for all mutable 
            /// or computed instance properties of this object.
            ///
            /// - Important: Don't store this instance in an external property. Accessing it after 
            /// the original object has been deallocated may result in a crash. Always access it directly 
            /// through the object that exposes it.
            ///
            \(inheritedAccessControlLevel)private(set) lazy var publisher = PropertyPublisher(object: self)
            """
        ]
    }
}
