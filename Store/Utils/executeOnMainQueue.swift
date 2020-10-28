//
//  executeOnMainQueue.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation

func executeOnMainQueue(block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async(execute: block)
    }
}
