//
//  ChooseCityCell.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import UIKit

struct ChooseCityCellCellModel: CollectionDescriptiveModel {
    var cellHeightForWidth: (CGFloat) -> (CGFloat)
    var descriptor: CollectionCellDescriptor
    
    init(props: ChooseCityCell.Props) {
        cellHeightForWidth = { _ in 60 }
        descriptor = .init(
            hashableBase: props
        ) { (cell: ChooseCityCell) in
            cell.props = props
        }
    }
}

class ChooseCityCell: UICollectionViewCell, Clearable {
    struct Props: Hashable {
        let title: String
        let selected: Bool
    }
    
    var props: Props? {
        didSet {
            render()
        }
    }
    
    var childrenToClear: [Clearable] {
        [titleLabel,
         selectedImageView,
        ]
    }
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var selectedImageView: UIImageView!
    
    private func render() {
        titleLabel.text = props?.title ?? ""
        selectedImageView.isHidden = props?.selected != true
    }
}
