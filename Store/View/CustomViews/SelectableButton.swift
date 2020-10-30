//
//  SelectableButton.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import UIKit

class SelectableButton: ActionButton {
    var customSelected: Bool? {
        didSet {
            UIView.animate(
                withCondition: oldValue != nil,
                duration: 0.3
            ) { [self] in
                isSelected = customSelected ?? false
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            updateBackgroundColor()
        }
    }
    
    override func initialize() {
        super.initialize()
        
        updateBackgroundColor()
    }
    
    private func updateBackgroundColor() {
        backgroundColor = isSelected ? .init(rgb: 0x001C3D, a: 0.05) : .vkBlue
    }
}
