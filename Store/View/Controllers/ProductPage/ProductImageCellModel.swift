//
//  ProductImageCell.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import UIKit

struct ProductImageCellModel: CollectionDescriptiveModel {
    typealias Cell = ImageCell
    
    var cellHeightForWidth: (CGFloat) -> (CGFloat)
    var descriptor: CollectionCellDescriptor
    
    init(props: Cell.Props) {
        cellHeightForWidth = { $0 }
        descriptor = .init { (cell: Cell) in
            cell.props = props
        }
    }
}
