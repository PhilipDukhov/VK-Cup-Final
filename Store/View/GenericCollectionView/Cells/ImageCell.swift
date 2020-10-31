//
//  ImageCell.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import UIKit

class ImageCell: UICollectionViewCell {
    struct Props: Hashable {
        let photoSizes: PhotoSizes?
    }
    
    var props: Props? {
        didSet {
            render()
        }
    }
    
    @IBOutlet private var imageView: UIImageView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        render()
    }
    
    private func render() {
        guard let props = props else { return }
        imageView.setImage(
            photoSizes: props.photoSizes
        )
    }
}
