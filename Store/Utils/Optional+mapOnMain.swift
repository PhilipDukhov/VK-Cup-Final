//
//  Optional+mapOnMain.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import Foundation

extension Optional {
    func mapOnMain(_ block: @escaping (Wrapped) -> Void) {
        map { wrapped in
            executeOnMainQueue {
                block(wrapped)
            }
        }
    }
}
