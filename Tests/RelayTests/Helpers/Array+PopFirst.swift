//
//  Array+PopFirst.swift
//  Publishable
//
//  Created by Kamil Strzelecki on 15/05/2025.
//  Copyright © 2025 Kamil Strzelecki. All rights reserved.
//

extension Array {

    mutating func popFirst() -> Element? {
        guard !isEmpty else {
            return nil
        }
        return removeFirst()
    }
}
