//
//  ImageTitleSubtitleCell.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import UIKit

class ImageTitleSubtitleCell: UICollectionViewCell {
    struct Props: Hashable {
        let photoSizes: PhotoSizes?
        let title: String
        let subtitle: String
    }
    
    var imageViewCornerRadius: CornerRadius = .zero
    var props: Props? {
        didSet {
            render()
        }
    }
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.setCornerRadius(imageViewCornerRadius)
        render()
    }
    
    private func render() {
        imageView.setImage(
            photoSizes: props?.photoSizes
        )
        titleLabel.text = props?.title ?? ""
        subtitleLabel.text = props?.subtitle ?? ""
    }
}
