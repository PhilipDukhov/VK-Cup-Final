//
//  CALayer+Animation.swift
//  Store
//
//  Created by Philip Dukhov on 10/31/20.
//

import QuartzCore

struct Animation<Layer: NSObject, Value> {
    let keyPath: ReferenceWritableKeyPath<Layer, Value>
    let fromValue: Value?
    let toValue: Value
    let duration: TimeInterval?
    let timingFunction: CAMediaTimingFunction?
    let beginFromCurrentState: Bool
    let skipAnimationIfCurrentValueNil: Bool
    
    init(
        keyPath: ReferenceWritableKeyPath<Layer, Value>,
        fromValue: Value? = nil,
        toValue: Value,
        duration: TimeInterval? = nil,
        timingFunction: CAMediaTimingFunction? = nil,
        beginFromCurrentState: Bool = false,
        skipAnimationIfCurrentValueNil: Bool = false
    ) {
        self.keyPath = keyPath
        self.fromValue = fromValue
        self.toValue = toValue
        self.duration = duration
        self.timingFunction = timingFunction
        self.beginFromCurrentState = beginFromCurrentState
        self.skipAnimationIfCurrentValueNil = skipAnimationIfCurrentValueNil
    }
}

extension CALayer {
    @discardableResult func animate<Value>(
        _ animation: Animation<CALayer, Value>,
        completionHandler: (() -> Void)? = nil)
    -> CABasicAnimation?
    {
        animateLayer(
            self,
            animation: animation
        )
    }
}

extension CAShapeLayer {
    @discardableResult func animate<Value>(
        _ animation: Animation<CAShapeLayer, Value>,
        completionHandler: (() -> Void)? = nil)
    -> CABasicAnimation?
    {
        animateLayer(
            self,
            animation: animation
        )
    }
}

@discardableResult private func animateLayer<Layer: CALayer, Value>(
    _ layer: Layer,
    animation: Animation<Layer, Value>,
    completionHandler: (() -> Void)? = nil)
-> CABasicAnimation?
{
    CATransaction.begin()
    CATransaction.setCompletionBlock(completionHandler)
    defer {
        // update actual value with the final one
        layer[keyPath: animation.keyPath] = animation.toValue
        CATransaction.commit()
    }
    // if duration is nil, let user handle it with
    // CATransaction outside for probably many animations
    guard
        animation.duration == nil ||
            animation.duration! > 0
    else { return nil }
    
    let fromValueLayer: Layer
    if animation.beginFromCurrentState,
       let presentation = layer.presentation()
    {
        fromValueLayer = presentation
    } else {
        fromValueLayer = layer
    }
    
    let currentValue = fromValueLayer[keyPath: animation.keyPath]
    if animation.skipAnimationIfCurrentValueNil {
        switch currentValue as Any? {
        case .none:
            return nil
            
        case .some(let value) where value as? CGFloat == 0:
            return nil
            
        default: break
        }
    }
    
    let basicAnimation = CABasicAnimation(
        keyPath: NSExpression(forKeyPath: animation.keyPath).keyPath
    )
    basicAnimation.timingFunction = animation.timingFunction
    basicAnimation.fromValue = animation.fromValue ?? fromValueLayer[keyPath: animation.keyPath]
    basicAnimation.toValue = animation.toValue
    animation.duration.map { basicAnimation.duration = $0 }
    
    layer.add(basicAnimation, forKey: basicAnimation.keyPath)
    return basicAnimation
}
