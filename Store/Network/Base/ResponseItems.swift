//
//  ResponseItems.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation

struct ResponseItems<Content: Decodable>: Decodable {
    let items: [Content]
}
