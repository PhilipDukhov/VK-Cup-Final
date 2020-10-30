//
//  Group.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation

struct Group: Codable, Identifiable {
    enum Visibility: Int, Codable {
        case opened
        case closed
    }
    
    let id: Int
    let name: String
    let visibility: Visibility
    var photoSizes: PhotoSizes {
        let sizes = [
            50: photo50,
            100: photo100,
            200: photo200,
        ].map {
            PhotoSize(type: .custom,
                 src: $0.value,
                 width: $0.key,
                 height: $0.key)
        }
        return PhotoSizes(sizes: sizes)
    }
    
    private let photo50: String
    private let photo100: String
    private let photo200: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case photo50 = "photo_50"
        case photo100 = "photo_100"
        case photo200 = "photo_200"
        case visibility = "is_closed"
    }
}
