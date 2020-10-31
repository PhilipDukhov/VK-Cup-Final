//
//  CoreGraphics+Extensions.swift
//  VK-Cup-C-Camera
//
//  Created by Philip Dukhov on 2/25/20.
//  Copyright © 2020 Philip Dukhov. All rights reserved.
//

import UIKit

public extension CGFloat {
    static let minControlSize: CGFloat = 45
    
    var roundedScreenScaled: CGFloat {
        return roundedScreenScaled(.toNearestOrAwayFromZero)
    }
    
    func roundedScreenScaled(
        _ rule: FloatingPointRoundingRule
    ) -> CGFloat {
         (self * UIScreen.main.nativeScale).rounded(rule) / UIScreen.main.nativeScale
    }
}

public extension CGPoint {
    var roundedScreenScaled: CGPoint {
        var point = self
        point.x = point.x.roundedScreenScaled
        point.y = point.y.roundedScreenScaled
        return point
    }
}

public extension CGSize {
    init(side: CGFloat) {
        self.init(width: side, height: side)
    }
    
    var roundedScreenScaled: CGSize {
        var size = self
        size.width = size.width.roundedScreenScaled
        size.height = size.height.roundedScreenScaled
        return size
    }
    
    var aspectRatio: CGFloat {
        width / height
    }
}

public extension CGRect {
    var roundedScreenScaled: CGRect {
        return CGRect(origin: origin.roundedScreenScaled, size: size.roundedScreenScaled)
    }
    
    var center: CGPoint {
        .init(x: midX, y: midY)
    }
    
    var controlOptimized: CGRect {
        return insetBy(dx: min(0, width - .minControlSize)/2,
                       dy: min(0, height - .minControlSize)/2)
    }
    
    func controlDistanceFromMid(to point: CGPoint) -> CGFloat? {
        if controlOptimized.contains(point) {
            return hypot(point.x - midX,
                         point.y - midY)
        }
        return nil
    }
    
    var aspectRatio: CGFloat {
        size.aspectRatio
    }
}

extension CGAffineTransform {
    var rotationAngle: CGFloat {
        return atan2(b, a)
    }
}
