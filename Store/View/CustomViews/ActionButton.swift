//
//  ActionButton.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import UIKit

class ActionButton: UIButton {
    var action: Action?
    
    init(action: Action? = nil) {
        self.action = action
        super.init(frame: .zero)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    func initialize() {
        addTarget(self, action: #selector(touchUpInside(button:)), for: .touchUpInside)
    }
    
    @objc private func touchUpInside(button: UIButton) {
        action?.execute()
    }
}
