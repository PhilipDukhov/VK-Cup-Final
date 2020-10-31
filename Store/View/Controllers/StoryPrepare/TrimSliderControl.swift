//
//  TrimSliderControl.swift
//  VK-Cup-C-Camera
//
//  Created by Philip Dukhov on 2/26/20.
//  Copyright © 2020 Philip Dukhov. All rights reserved.
//

import UIKit

class TrimSliderControl: UIControl {
    private enum Constants {
        static let playbackViewSize = CGSize(width: 4, height: 80)
        static let thumbsViewWidth: CGFloat = 16
        static let selectedBorderWidth: CGFloat = 2
    }
    enum TrackingControl: CaseIterable {
        case minThumb
        case maxThumb
        case midThumb
        case playbackThumb
        
        case none
        
        static let allControls: [Self] = allCases.dropLast()
    }
    
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var playbackView: UIView!
    
    @IBOutlet weak var minThumbView: UIView! {
        didSet {
            minThumbView.round(corners: [.topLeft, .bottomLeft], radius: 8)
        }
    }
    @IBOutlet weak var maxThumbView: UIView!{
        didSet {
            maxThumbView.round(corners: [.topRight, .bottomRight], radius: 8)
        }
    }
    @IBOutlet weak var selectedBorderView: UIView!
    
    @IBOutlet weak var minSelectedValueLabel: UILabel!
    @IBOutlet weak var maxSelectedValueLabel: UILabel!
    
    @IBOutlet weak var playbackPositionConstraint: NSLayoutConstraint!
    @IBOutlet weak var minThumbPositionConstraint: NSLayoutConstraint!
    @IBOutlet weak var maxThumbPositionConstraint: NSLayoutConstraint!
    
    var seeking: Bool { trackingControl != .none }
    
    class override var requiresConstraintBasedLayout: Bool { true }
    
    var minValue: TimeInterval {
        get { _minValue }
        set {
            guard _minValue != newValue else { return }
            _minValue = newValue
            minSelectedValue = newValue
            setNeedsLayout()
        }
    }
    
    var maxValue: TimeInterval {
        get { _maxValue }
        set {
            guard _maxValue != newValue else { return }
            _maxValue = newValue
            maxSelectedValue = newValue
            setNeedsLayout()
        }
    }
    
    var minSelectedValue: TimeInterval = 0 {
        didSet {
            guard minSelectedValue != oldValue else { return }
            setNeedsLayout()
        }
    }
    
    var maxSelectedValue: TimeInterval = 1 {
        didSet {
            guard maxSelectedValue != oldValue else { return }
            setNeedsLayout()
        }
    }
    
    var minSelectionRange: TimeInterval {
        get { _minSelectionRange }
        set {
            let newValue = max(newValue, 0)
            guard _minSelectionRange != newValue else { return }
            _minSelectionRange = newValue
            setNeedsLayout()
        }
    }
    
    var value: TimeInterval {
        get { return _value }
        set {
            let newValue = min(max(newValue, minSelectedValue), maxSelectedValue)
            guard _value != newValue else { return }
            _value = newValue
            setNeedsLayout()
        }
    }
    
    var currentScrubValue: TimeInterval {
        switch trackingControl {
        case .minThumb, .midThumb:
            return minSelectedValue
            
        case .maxThumb:
            return maxSelectedValue
            
        case .none, .playbackThumb:
            return value
        }
    }
    
    private(set) var trackingControl = TrackingControl.none
    
    // MARK: - Privates
    
    private var _minValue: TimeInterval = 0
    private var _maxValue: TimeInterval = 30
    private var _minSelectionRange: TimeInterval = 1
    private var _value: TimeInterval = 0
    
    private var minPosition: CGFloat { minThumbView.bounds.width }
    
    private var maxPosition: CGFloat { backgroundView.bounds.width - maxThumbView.bounds.width }
    
    private var initialPoint: CGPoint!
    private weak var tapTimer: Timer?
    
    // MARK: - View lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        playbackPositionConstraint.constant = position(for: value)
        minThumbPositionConstraint.constant = position(for: minSelectedValue)
        maxThumbPositionConstraint.constant = position(for: maxSelectedValue)
        
        [minSelectedValueLabel: minSelectedValue,
         maxSelectedValueLabel: maxSelectedValue,
        ].forEach {
            $0.key.text = stringRepresentation(value: $0.value)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setNeedsLayout()
    }
    
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        subview.isUserInteractionEnabled = false
    }
    
    // MARK: - UIControl
    
    func shouldBeginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return nearestControl(toTouch: touch) != .none
    }
    
    private var isScrubbing = false
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        initialPoint = touch.location(in: self)
        trackingControl = nearestControl(toTouch: touch)
        isScrubbing = trackingControl != .none
        if isScrubbing {
            initialPoint.x -= constant(for: trackingControl)!
        }
        return isScrubbing
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard trackingControl != .none else { return tapTimer != nil }
        tapTimer?.invalidate()
        setValueForCurrentTrackingControl(value(for: touch.location(in: self).x - initialPoint.x))
        sendActions(for: .valueChanged)
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        tapTimer?.fire()
        trackingControl = .none
        initialPoint = nil
        isScrubbing = false
    }
    
    // MARK: - Helpers
    
    private func nearestControl(toTouch touch: UITouch) -> TrackingControl {
        var nearestControl = (TrackingControl.none, CGFloat.greatestFiniteMagnitude)
        for control in TrackingControl.allControls {
            if control == .midThumb,
               minValue == minSelectedValue,
               maxValue == maxSelectedValue
            {
                continue
            }
            if let controlView = view(for: control),
               let distance = controlView.frame
                .controlDistanceFromMid(
                    to: touch.location(in: controlView.superview)
                ),
               distance <= nearestControl.1
            {
                nearestControl = (control, distance)
            }
        }
        return nearestControl.0
    }
    
    func position(for value: TimeInterval) -> CGFloat {
        let result = (minPosition + (maxPosition - minPosition) * CGFloat((value - minValue) / (maxValue - minValue))).roundedScreenScaled
        return result.isFinite ? result : 0
    }
    
    func value(for position: CGFloat) -> TimeInterval {
        let result = minValue + TimeInterval(position - minPosition) * (maxValue - minValue) / TimeInterval(maxPosition - minPosition)
        return result.isFinite ? result : 0
    }
    
    private func view(for trackingControl: TrackingControl) -> UIView? {
        let view: UIView
        switch trackingControl {
        case .none:
            return nil
            
        case .playbackThumb:
            view = playbackView
            
        case .minThumb:
            view = minThumbView
            
        case .maxThumb:
            view = maxThumbView
            
        case .midThumb:
            view = selectedBorderView
        }
        return view
    }
    
    private func update(view: UIView?, withPositionX position: CGFloat) {
        guard let view = view else {return}
        var frame = view.frame
        frame.origin.x = position
        view.frame = frame
    }
    
    private func update(view: UIView?, withWidth width: CGFloat) {
        guard let view = view else {return}
        var frame = view.frame
        frame.size.width = width
        view.frame = frame
    }
    
    private func constraint(for trackingControl: TrackingControl) -> NSLayoutConstraint? {
        switch trackingControl {
        case .minThumb, .midThumb:
            return minThumbPositionConstraint
            
        case .maxThumb:
            return maxThumbPositionConstraint
            
        case .playbackThumb:
            return playbackPositionConstraint
            
        case .none:
            return nil
        }
    }
    
    private func constant(for trackingControl: TrackingControl) -> CGFloat? {
        return constraint(for: trackingControl)?.constant
    }
    
    func setValueForCurrentTrackingControl(_ newValue: TimeInterval) {
        switch trackingControl {
        case .minThumb:
            minSelectedValue = max(min(newValue, maxSelectedValue - minSelectionRange), minValue)
            
        case .maxThumb:
            maxSelectedValue = min(max(newValue, minSelectedValue + minSelectionRange), maxValue)
            
        case .midThumb:
            let range = maxSelectedValue - minSelectedValue
            minSelectedValue = max(minValue, min(newValue, maxValue - range))
            maxSelectedValue = minSelectedValue + range
            
        case .playbackThumb:
            value = newValue
            
        case .none: break
        }
        value = currentScrubValue
    }
    
    private func stringRepresentation(value: TimeInterval) -> String {
        String(format: "%02d:%02d", Int(value) / 60, Int(value.rounded()) % 60)
    }
}
