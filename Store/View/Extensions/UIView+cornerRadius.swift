//
//  UIView+cornerRadius.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import UIKit

extension UIView {
    enum CornerRadius {
        case zero
        case `static`(CGFloat)
        case circle
    }
    
    func setCornerRadius(_ cornerRadius: CornerRadius) {
        switch cornerRadius {
        case .zero:
            layer.cornerRadius = 0
            
        case .static(let cornerRadius):
            layer.cornerRadius = cornerRadius
            
        case .circle:
            layer.cornerRadius = max(bounds.width, bounds.height) / 2
        }
    }
}
