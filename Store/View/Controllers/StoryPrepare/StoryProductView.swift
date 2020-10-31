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
        imageView.frame.size = .init(side: UIScreen.main.bounds.width / 2)
        imageView.setImage(photoSizes: product.photos.first!.sizes)
        layer.borderColor = UIColor.vkBlue.cgColor
        clipsToBounds = true
        backgroundColor = .white
        
        translatesAutoresizingMaskIntoConstraints = false
        let container = UIView()
        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        [imageView,
         titleLabel,
         priceLabel,
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }
        NSLayoutConstraint.activate([
            widthConstraints,
            container.widthAnchor.constraint(
                equalTo: widthAnchor,
                multiplier: 0.9
            ),
            container.heightAnchor.constraint(
                equalTo: heightAnchor,
                multiplier: 0.9
            ),
            container.centerXAnchor.constraint(
                equalTo: centerXAnchor
            ),
            container.centerYAnchor.constraint(
                equalTo: centerYAnchor
            ),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
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
            titleLabel.widthAnchor.constraint(
                equalTo: container.widthAnchor
            ),
            titleLabel.centerXAnchor.constraint(
                equalTo: container.centerXAnchor
            ),
            titleLabel.bottomAnchor.constraint(
                equalTo: priceLabel.topAnchor
            ),
            priceLabel.widthAnchor.constraint(
                equalTo: container.widthAnchor
            ),
            priceLabel.bottomAnchor.constraint(
                equalTo: container.bottomAnchor
            ),
            priceLabel.centerXAnchor.constraint(
                equalTo: container.centerXAnchor
            ),
        ])
        widthUpdated()
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func widthUpdated() {
        let size = width / 12
        titleLabel.font = .systemFont(ofSize: size)
        priceLabel.font = .systemFont(ofSize: size, weight: .medium)
        layer.borderWidth = width / 50
        layer.cornerRadius = width / 10
        imageView.layer.cornerRadius = width / 10
    }
    
    private func updatePriceLabel() {
        priceLabel.text = priceLabelShowed ? product.price.text : ""
    }
}
