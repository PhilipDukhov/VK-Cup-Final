//
//  MarketListCell.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import UIKit

struct MarketListCellModel: CollectionDescriptiveModel {
    var cellHeightForWidth: (CGFloat) -> (CGFloat)
    var descriptor: CollectionCellDescriptor
    
    init(props: MarketListCell.Props) {
        cellHeightForWidth = { _ in 60 }
        descriptor = .init { (cell: MarketListCell) in
            cell.props = props
        }
    }
}

class MarketListCell: UICollectionViewCell {
    struct Props {
        let photoSizes: PhotoSizes
        let title: String
        let subtitle: String
        
        static let zero = Self(photoSizes: .zero, title: "", subtitle: "")
    }
    
    @IBOutlet private var photoImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    
    var props: Props = .zero {
        didSet {
            render()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        photoImageView.layer.cornerRadius = photoImageView.bounds.height / 2
        render()
    }
    
    private func render() {
        props.photoSizes
            .bestQualityPhoto(forContainer: bounds.size)
            .map { photoImageView.setImage(url: $0.url) }
        titleLabel.text = props.title
        subtitleLabel.text = props.subtitle
    }
}
