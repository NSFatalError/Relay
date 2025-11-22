//
//  PublisherDeclBuilder.swift
//  Relay
//
//  Created by Kamil Strzelecki on 12/01/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

internal struct PublisherDeclBuilder: ClassDeclBuilder, MemberBuilding {

    let declaration: ClassDeclSyntax
    let properties: PropertiesList

    var maxAllowedAccessControlLevel: AccessControlLevel {
        .open
    }

    func build() -> [DeclSyntax] {
        [
            """
            private lazy var _publisher = PropertyPublisher(object: self)
            """,
            """
            /// A ``PropertyPublisher`` which exposes `Combine` publishers for all mutable 
            /// or computed instance properties of this object.
            ///
            /// - Important: Don't store this instance in an external property. Accessing it after 
            /// the original object has been deallocated may result in a crash. Always access it directly 
            /// through the object that exposes it.
            ///
            \(inheritedAccessControlLevel)var publisher: PropertyPublisher {
                _publisher
            }
            """
        ]
    }
}
