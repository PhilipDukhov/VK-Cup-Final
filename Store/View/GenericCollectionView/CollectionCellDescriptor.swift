//
//  CollectionCellDescriptor.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import UIKit

struct CollectionCellDescriptor {
    let cellClass: UICollectionViewCell.Type
    let reuseIdentifier: String
    let configure: (UICollectionViewCell) -> Void
    
    init<T: UICollectionViewCell>(
        configure: @escaping (T) -> Void,
        customReuseIdentifier: String? = nil
    ) {
        self.cellClass = T.self
        self.reuseIdentifier = customReuseIdentifier ?? String(describing: T.self)
        self.configure = { cell in
            // swiftlint:disable:next force_cast force_unwrapping
            configure(cell as! T)
        }
    }
}
