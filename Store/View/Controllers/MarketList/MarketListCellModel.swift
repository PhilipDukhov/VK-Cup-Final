//
//  MarketListCell.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import UIKit

struct MarketListCellModel: CollectionDescriptiveModel {
    typealias Cell = ImageTitleSubtitleCell
    
    var cellHeightForWidth: (CGFloat) -> (CGFloat)
    var descriptor: CollectionCellDescriptor
    
    init(props: Cell.Props) {
        cellHeightForWidth = { _ in 60 }
        descriptor = .init { (cell: Cell) in
            cell.props = props
            cell.imageViewCornerRadius = .circle
        }
    }
}
