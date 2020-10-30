//
//  NSError+description.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import Foundation

extension NSError {
    convenience init(description: String, code: Int = 0) {
        self.init(
            domain: Bundle.main.displayName,
            code: code,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }
}
