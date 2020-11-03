//
//  MarketListTitleView.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import UIKit

class MarketListTitleView: UIView {
    struct Props {
        let title: String
        let action: Action
    }
    
    var props: Props? {
        didSet {
            executeOnMainQueue { [self] in
                setNeedsLayout()
            }
        }
    }
    
    private let titleLabel = UILabel().apply {
        $0.font = .navigationBarTitleFont
    }
    private let dropdownImageView = UIImageView(
        image: R.image.dropdown_16()
    )
    
    private var desiredWidth: CGFloat?
        
    override func layoutSubviews() {
        isHidden = props == nil
        guard let props = props else {
            return
        }
        titleLabel.text = props.title
        titleLabel.sizeToFit()
        
        // if view width is much bigger than screen width,
        // layoutSubviews gets called infinitely until width shortened
        let extraWidth = dropdownImageView.bounds.width + .imageMargin + .distance
        var width = titleLabel.bounds.width + extraWidth
        let superviewRequestsSmallerSize = width == desiredWidth
        desiredWidth = width
        if superviewRequestsSmallerSize {
            width = min(
                width,
                superview?.bounds.width ?? .infinity
            )
        }
        titleLabel.frame.size.width = frame.size.width - extraWidth
        frame.size = .init(
            width: width,
            height: titleLabel.bounds.height
        )
        dropdownImageView.frame.origin = .init(
            x: titleLabel.bounds.width + .distance,
            y: (frame.height - dropdownImageView.frame.height) / 2 + .imageCenterYOffset
        )
    }
    
    init() {
        super.init(frame: .zero)
        addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(tapHandler)
            )
        )
        [titleLabel,
         dropdownImageView
        ].forEach(addSubview)
    }
    
    @objc private func tapHandler() {
        props?.action.execute()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension CGFloat {
    static let distance: Self = 7
    static let imageMargin: Self = 3
    static let imageCenterYOffset: Self = 1
}
