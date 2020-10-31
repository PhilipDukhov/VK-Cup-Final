//
//  ProductListCell.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import UIKit

struct ProductListCellModel: CollectionDescriptiveModel {
    typealias Cell = ImageTitleSubtitleCell
    
    var cellHeightForWidth: (CGFloat) -> (CGFloat)
    var descriptor: CollectionCellDescriptor
    
    init(props: Cell.Props) {
        cellHeightForWidth = { $0 + 58 }
        descriptor = .init(
            hashableBase: props
        ) { (cell: Cell) in
            cell.props = props
            cell.imageViewCornerRadius = .static(10)
        }
    }
}
