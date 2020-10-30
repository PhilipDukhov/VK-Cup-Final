//
//  Bundle+displayName.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import Foundation

extension Bundle {
    var displayName: String {
        // swiftlint:disable:next force_cast
        object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String
    }
}
