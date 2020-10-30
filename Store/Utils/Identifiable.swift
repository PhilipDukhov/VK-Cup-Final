//
//  Identifiable.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import Foundation

protocol Identifiable: Equatable {
    
    /// A type representing the stable identity of the entity associated with
    /// an instance.
    // swiftlint:disable:next type_name
    associatedtype ID: Hashable
    
    /// The stable identity of the entity associated with this instance.
    var id: Self.ID { get }
}

extension Identifiable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension Array where Element: Identifiable {
    mutating func insertOrMove(_ newElement: Element, at i: Int) {
        firstIndex(of: newElement).map {
            _ = remove(at: $0)
        }
        insert(newElement, at: i)
    }
}
