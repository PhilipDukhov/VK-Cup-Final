//
//  UIView+animateWithCondition.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import UIKit

extension UIView {
    @IBInspectable var borderColor: UIColor? {
        get {
            guard let borderColor = layer.borderColor else { return nil }
            return .init(cgColor: borderColor)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    func round(corners: UIRectCorner, radius: CGFloat) {
        let mask = CAShapeLayer()
        mask.path = UIBezierPath(roundedRect: bounds,
                                 byRoundingCorners: corners,
                                 cornerRadii: CGSize(width: radius, height: radius)).cgPath
        layer.mask = mask
    }
}

extension UIView {
    static func animate(
        withCondition condition: Bool,
        duration: TimeInterval,
        animations: @escaping () -> Void
    ) {
        if condition {
            animate(withDuration: duration, animations: animations)
        } else {
            animations()
        }
    }
}
