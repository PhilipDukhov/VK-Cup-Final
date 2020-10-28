//
//  IndexPathDifference.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation
import DeepDiff

enum IndexPathDifference {
    case move(at: IndexPath, to: IndexPath)
    case delete(at: IndexPath)
    case insert(at: IndexPath)
    case replace(at: IndexPath)
    case reload(section: Int)
    
}

@available(iOS 13, *)
extension CollectionDifference {
    func indexPathDifference(
        for section: Int
    ) -> [IndexPathDifference] {
        (insertions + removals).compactMap {
            switch $0 {
            case let .remove(offset, _, associatedWith):
                guard let associatedWith = associatedWith else {
                    return .delete(at: IndexPath(row: offset, section: section))
                }
                return .move(
                    at: IndexPath(row: offset, section: section),
                    to: IndexPath(row: associatedWith, section: section)
                )
                
            case let .insert(offset, _, associatedWith)
                    where associatedWith == nil:
                return .insert(at: IndexPath(row: offset, section: section))
                
            default: return nil
            }
        }
    }
}

extension Change {
    func indexPathDifference(
        for section: Int
    ) -> IndexPathDifference {
        switch self {
        case let .move(info):
            return .move(
                at: IndexPath(row: info.fromIndex, section: section),
                to: IndexPath(row: info.toIndex, section: section)
            )
            
        case let .delete(info):
            return .delete(at: IndexPath(row: info.index, section: section))
            
        case let .insert(info):
            return .insert(at: IndexPath(row: info.index, section: section))
            
        case let .replace(info):
            return .replace(at: IndexPath(row: info.index, section: section))
        }
    }
}

extension Array where Element: DiffAware, Element: Hashable {
    func indexPathDifference(for section: Int, from other: [Element]?) -> [IndexPathDifference]? {
        guard let other = other else { return nil }
        if #available(iOS 13, *) {
            return difference(from: other, by: ==)
                .inferringMoves()
                .indexPathDifference(for: section)
        } else {
            return diff(old: other, new: self)
                .map { $0.indexPathDifference(for: section) }
        }
    }
}
