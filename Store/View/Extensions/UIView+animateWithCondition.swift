//
//  UIView+animateWithCondition.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import UIKit

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
