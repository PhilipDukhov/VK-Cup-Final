//
//  CollectionCellDescriptor.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import UIKit
import DeepDiff

struct CollectionCellDescriptor: DiffAware, Hashable {
    let cellClass: UICollectionViewCell.Type
    let reuseIdentifier: String
    let configure: (UICollectionViewCell) -> Void
    
    private let hashableBase: AnyHashable
    
    init<T: UICollectionViewCell>(
        hashableBase: AnyHashable,
        customReuseIdentifier: String? = nil,
        configure: @escaping (T) -> Void
    ) {
        self.cellClass = T.self
        self.reuseIdentifier = customReuseIdentifier ?? String(describing: T.self)
        self.configure = { cell in
            // swiftlint:disable:next force_cast force_unwrapping
            configure(cell as! T)
        }
        self.hashableBase = hashableBase
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(hashableBase)
    }
    
    static func == (lhs: CollectionCellDescriptor, rhs: CollectionCellDescriptor) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
