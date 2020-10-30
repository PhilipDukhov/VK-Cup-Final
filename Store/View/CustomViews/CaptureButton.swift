//
//  CaptureButton.swift
//  VK-Cup-C-Camera
//
//  Created by Philip Dukhov on 2/25/20.
//  Copyright © 2020 Philip Dukhov. All rights reserved.
//

import UIKit

@objc protocol CaptureButtonDelegate: class {
    func captureButtonBeginTracking(_ button: CaptureButton)
    func captureButtonEndTracking(_ button: CaptureButton)
    func captureButton(_ button: CaptureButton, zoomChanged zoom: CGFloat)
}

class CaptureButton: UIControl {
    private enum Constants {
        static let defaultMultiplier: CGFloat = 64 / 96
        static let preparingToRecordMultiplier: CGFloat = 48 / 96
        static let recordingMultiplier: CGFloat = 84 / 96
        static let ringWidthPart: CGFloat = 0.1
        static let ringOffsetPart: CGFloat = ringWidthPart / 3
        
        static let maxZoomOffset: CGFloat = UIScreen.main.bounds.height / 2
        
        static let progressAnimationPath = "strokeEnd"
    }
    
    enum ButtonState {
        case `default`
        case preparingToRecord
        case recording(maxDuration: TimeInterval)
        case recorded
        
        var multiplier: CGFloat {
            switch self {
            case .default, .recorded:
                return Constants.defaultMultiplier
                
            case .preparingToRecord:
                return Constants.preparingToRecordMultiplier
                
            case .recording:
                return Constants.recordingMultiplier
            }
        }
    }
    
    private let ovalLayer: CAShapeLayer = {
        let ovalLayer = CAShapeLayer()
        ovalLayer.lineWidth = 0
        ovalLayer.strokeColor = UIColor.white.cgColor
        ovalLayer.fillColor = UIColor.clear.cgColor
        return ovalLayer
    }()
    
    private let progressLayer: CAShapeLayer = {
        let progressLayer = CAShapeLayer()
        progressLayer.lineWidth = 0
        progressLayer.strokeColor = UIColor.captureProgress.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        return progressLayer
    }()
    
    private let ringLayer: CAShapeLayer = {
        let ringLayer = CAShapeLayer()
        ringLayer.lineWidth = 0
        ringLayer.fillColor = UIColor.captureRing.cgColor
        return ringLayer
    }()
       
    var buttonState: ButtonState = .default {
        didSet {
            updateShape()
        }
    }
    
    var zoom: CGFloat = 0 // 0...1
    
    @IBOutlet weak var delegate: CaptureButtonDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        [ovalLayer,
         progressLayer,
         ringLayer,
        ].forEach(layer.addSublayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateShape()
    }
    
    private func updateShape() {
        [ovalLayer,
         progressLayer,
         ringLayer,
        ].forEach {
            $0.frame = bounds
        }
        switch buttonState {
        case .default:
            progressLayer.strokeEnd = 0
            
        case .preparingToRecord:
            break
            
        case .recording(let maxDuration):
            let animation = CABasicAnimation(keyPath: Constants.progressAnimationPath)
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = maxDuration
            progressLayer.add(animation, forKey: Constants.progressAnimationPath)
            
        case .recorded:
            progressLayer.strokeEnd = progressLayer.presentation()?.strokeEnd ?? 1
            progressLayer.removeAllAnimations()
        }
        let side = min(bounds.width, bounds.height) * buttonState.multiplier
        [ovalLayer,
         progressLayer,
        ].forEach {
            $0.animateIfNonNull(lineWidth: side * Constants.ringWidthPart)
            $0.animateIfNonNull(path: UIBezierPath(arcCenter: bounds.center,
                                                   radius: side / 2 - $0.lineWidth / 2,
                                                   startAngle: -.pi / 2,
                                                   endAngle: .pi * 3 / 2,
                                                   clockwise: true).cgPath)
        }
        
        let ringSide = side * (1 - (Constants.ringWidthPart + Constants.ringOffsetPart) * 2)
        
        ringLayer.animateIfNonNull(path: UIBezierPath(arcCenter: bounds.center,
                                                      radius: ringSide / 2,
                                                      startAngle: 0,
                                                      endAngle: .pi * 2,
                                                      clockwise: true).cgPath)
    }
    
    private var initialPoint: CGPoint!
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        delegate?.captureButtonBeginTracking(self)
        initialPoint = touch.location(in: self)
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        zoom = min(1, max(0, (initialPoint.y - touch.location(in: self).y) / Constants.maxZoomOffset))
        delegate?.captureButton(self, zoomChanged: zoom)
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        delegate?.captureButtonEndTracking(self)
    }
}
