//
//  RelayedPropertyDeclAccessorBuilder.swift
//  Relay
//
//  Created by Kamil Strzelecki on 30/11/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

import SwiftSyntaxMacros

internal struct RelayedPropertyDeclAccessorBuilder: PropertyDeclAccessorBuilder {

    let declaration: Property

    func buildAccessors() -> [AccessorDeclSyntax] {
        [
            initAccessor(),
            getAccessor(),
            setAccessor(),
            modifyAccessor()
        ]
    }

    private func initAccessor() -> AccessorDeclSyntax {
        """
        @storageRestrictions(initializes: _\(declaration.trimmedName))
        init(initialValue) {
            _\(declaration.trimmedName) = initialValue
        }
        """
    }

    private func getAccessor() -> AccessorDeclSyntax {
        if declaration.isStoredObservationTracked {
            """
            get {
                _$observationRegistrar.access(self, keyPath: \\.\(declaration.trimmedName))
                return _\(declaration.trimmedName)
            }
            """
        } else {
            """
            get {
                return _\(declaration.trimmedName)
            }
            """
        }
    }

    private func setAccessor() -> AccessorDeclSyntax {
        if declaration.isStoredObservationTracked {
            if declaration.isStoredPublisherTracked {
                """
                set {
                    guard shouldNotifyObservers(_\(declaration.trimmedName), newValue) else {
                        _\(declaration.trimmedName) = newValue
                        return
                    }

                    publisher._beginModifications()
                    _$observationRegistrar.willSet(self, keyPath: \\.\(declaration.trimmedName))
                    _\(declaration.trimmedName) = newValue
                    _$observationRegistrar.didSet(self, keyPath: \\.\(declaration.trimmedName))
                    publisher._\(declaration.trimmedName).send(newValue)
                    publisher._endModifications()
                }
                """
            } else {
                """
                set {
                    guard shouldNotifyObservers(_\(declaration.trimmedName), newValue) else {
                        _\(declaration.trimmedName) = newValue
                        return
                    }

                    _$observationRegistrar.willSet(self, keyPath: \\.\(declaration.trimmedName))
                    _\(declaration.trimmedName) = newValue
                    _$observationRegistrar.didSet(self, keyPath: \\.\(declaration.trimmedName))
                }
                """
            }
        } else {
            """
            set {
                guard shouldNotifyObservers(_\(declaration.trimmedName), newValue) else {
                    _\(declaration.trimmedName) = newValue
                    return
                }

                publisher._beginModifications()
                _\(declaration.trimmedName) = newValue
                publisher._\(declaration.trimmedName).send(newValue)
                publisher._endModifications()
            }
            """
        }
    }

    private func modifyAccessor() -> AccessorDeclSyntax {
        if declaration.isStoredObservationTracked {
            if declaration.isStoredPublisherTracked {
                """
                _modify {
                    publisher._beginModifications()
                    _$observationRegistrar.access(self, keyPath: \\.\(declaration.trimmedName))
                    _$observationRegistrar.willSet(self, keyPath: \\.\(declaration.trimmedName))

                    defer { 
                        _$observationRegistrar.didSet(self, keyPath: \\.\(declaration.trimmedName))
                        publisher._\(declaration.trimmedName).send(_\(declaration.trimmedName))
                        publisher._endModifications()
                    }

                    yield &_\(declaration.trimmedName)
                }
                """
            } else {
                """
                _modify {            
                    _$observationRegistrar.access(self, keyPath: \\.\(declaration.trimmedName))
                    _$observationRegistrar.willSet(self, keyPath: \\.\(declaration.trimmedName))

                    defer { 
                        _$observationRegistrar.didSet(self, keyPath: \\.\(declaration.trimmedName))
                    }

                    yield &_\(declaration.trimmedName)
                }
                """
            }
        } else {
            """
            _modify {  
                publisher._beginModifications()

                defer { 
                    publisher._\(declaration.trimmedName).send(_\(declaration.trimmedName))
                    publisher._endModifications()
                }

                yield &_\(declaration.trimmedName)
            }
            """
        }
    }
}
