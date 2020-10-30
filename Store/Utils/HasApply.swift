//
//  HasApply.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation

protocol HasApply { }

extension HasApply {
    func apply(closure: (Self) -> Void) -> Self {
        closure(self)
        return self
    }
}

extension NSObject: HasApply { }
