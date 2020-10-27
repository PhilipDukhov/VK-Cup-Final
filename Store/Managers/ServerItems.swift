//
//  ServerItems.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation

struct ServerItems<Content: Codable>: Codable {
    let items: [Content]
}
