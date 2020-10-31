//
//  StoryProductView.swift
//  Store
//
//  Created by Philip Dukhov on 10/31/20.
//

import UIKit

class StoryProductView: UIView {
    let product: Product
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel().apply {
        $0.numberOfLines = 2
    }
    private let priceLabel = UILabel()
    
    var priceLabelShowed = true {
        didSet {
            updatePriceLabel()
        }
    }
    
    private lazy var widthConstraints = widthAnchor.constraint(equalToConstant: 150)
    
    var width: CGFloat {
        get { widthConstraints.constant }
        set {
            widthConstraints.constant = newValue
            widthUpdated()
        }
    }
    
    init(product: Product) {
        self.product = product
        super.init(frame: .zero)
        titleLabel.text = product.title
        updatePriceLabel()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame.size = .init(side: UIScreen.main.bounds.width / 2)
        let photo = product.photos.first
        photo.map { imageView.setImage(photoSizes: $0.sizes) }
        layer.borderColor = UIColor.vkBlue.cgColor
        clipsToBounds = true
        backgroundColor = .white
        
        translatesAutoresizingMaskIntoConstraints = false
        let container = UIView()
        let leftMargin = UIView()
        let topMargin = UIView()
        let rightMargin = UIView()
        let bottomMargin = UIView()
        [container,
         leftMargin,
         topMargin,
         rightMargin,
         bottomMargin,
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        [imageView,
         titleLabel,
         priceLabel,
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }
        var constraints = [
            widthConstraints,
        ]
        titleLabel.apply {
            constraints += [
                $0.widthAnchor.constraint(
                    equalTo: container.widthAnchor
                ),
                $0.centerXAnchor.constraint(
                    equalTo: container.centerXAnchor
                ),
                $0.bottomAnchor.constraint(
                    equalTo: priceLabel.topAnchor
                ),
            ]
        }
        priceLabel.apply {
            constraints += [
                $0.widthAnchor.constraint(
                    equalTo: container.widthAnchor
                ),
                $0.centerXAnchor.constraint(
                    equalTo: container.centerXAnchor
                ),
                $0.bottomAnchor.constraint(
                    equalTo: container.bottomAnchor
                ),
            ]
        }
        leftMargin.apply {
            constraints += [
                $0.leftAnchor.constraint(
                    equalTo: leftAnchor
                ),
                $0.topAnchor.constraint(
                    equalTo: topAnchor
                ),
                $0.bottomAnchor.constraint(
                    equalTo: bottomAnchor
                ),
                $0.rightAnchor.constraint(
                    equalTo: container.leftAnchor
                ),
                $0.widthAnchor.constraint(
                    equalTo: widthAnchor,
                    multiplier: (1 - .contentWidthPart) / 2
                ),
            ]
        }
        topMargin.apply {
            constraints += [
                $0.leftAnchor.constraint(
                    equalTo: leftAnchor
                ),
                $0.topAnchor.constraint(
                    equalTo: topAnchor
                ),
                $0.bottomAnchor.constraint(
                    equalTo: container.topAnchor
                ),
                $0.rightAnchor.constraint(
                    equalTo: rightAnchor
                ),
                $0.heightAnchor.constraint(
                    equalTo: leftMargin.widthAnchor
                ),
            ]
        }
        rightMargin.apply {
            constraints += [
                $0.leftAnchor.constraint(
                    equalTo: container.rightAnchor
                ),
                $0.topAnchor.constraint(
                    equalTo: topAnchor
                ),
                $0.bottomAnchor.constraint(
                    equalTo: bottomAnchor
                ),
                $0.rightAnchor.constraint(
                    equalTo: rightAnchor
                ),
                $0.widthAnchor.constraint(
                    equalTo: leftMargin.widthAnchor
                ),
            ]
        }
        bottomMargin.apply {
            constraints += [
                $0.leftAnchor.constraint(
                    equalTo: leftAnchor
                ),
                $0.topAnchor.constraint(
                    equalTo: container.bottomAnchor
                ),
                $0.bottomAnchor.constraint(
                    equalTo: bottomAnchor
                ),
                $0.rightAnchor.constraint(
                    equalTo: rightAnchor
                ),
                $0.heightAnchor.constraint(
                    equalTo: leftMargin.widthAnchor
                ),
            ]
        }
        
        if let photo = photo {
            let sizes = photo.sizes.sizes.last
            var photoRatio: CGFloat?
            if
                let width = photo.width ?? sizes?.width,
                let height = photo.height ?? sizes?.height
            {
                photoRatio = CGFloat(width) / CGFloat(height)
            }
            constraints += [
                imageView.widthAnchor.constraint(
                    equalTo: imageView.heightAnchor,
                    multiplier: photoRatio ?? 1
                ),
                imageView.leftAnchor.constraint(
                    equalTo: container.leftAnchor
                ),
                imageView.rightAnchor.constraint(
                    equalTo: container.rightAnchor
                ),
                imageView.topAnchor.constraint(
                    equalTo: container.topAnchor
                ),
                imageView.bottomAnchor.constraint(
                    equalTo: titleLabel.topAnchor
                ),
            ]
        } else {
            constraints += [
                titleLabel.topAnchor.constraint(
                    equalTo: container.topAnchor
                ),
            ]
        }
        NSLayoutConstraint.activate(constraints)
        widthUpdated()
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func widthUpdated() {
        let textSize = width / 12
        titleLabel.font = .systemFont(ofSize: textSize)
        priceLabel.font = .systemFont(ofSize: textSize, weight: .medium)
        layer.borderWidth = width / 50
        layer.cornerRadius = width / 10
        imageView.layer.cornerRadius = layer.cornerRadius * .contentWidthPart
    }
    
    private func updatePriceLabel() {
        priceLabel.text = priceLabelShowed ? product.price.text : ""
    }
}

extension CGFloat {
    static let contentWidthPart: CGFloat = 0.9
}
