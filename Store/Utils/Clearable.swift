//
//  Clearable.swift
//  Store
//
//  Created by Philip Dukhov on 11/1/20.
//

import UIKit

protocol Clearable: class {
    var childrenToClear: [Clearable] { get }
    
    func clear()
}

extension Clearable {
    
    func clear() {
        childrenToClear.forEach { $0.clear() }
    }
}

extension UILabel: Clearable {
    var childrenToClear: [Clearable] { [] }
    
    func clear() {
        text = nil
    }
}
