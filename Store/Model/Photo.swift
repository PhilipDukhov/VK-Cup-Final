//
//  Photo.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation

struct Photo: Codable, Hashable, Identifiable {
    let id: Int
    let albumId: Int
    let ownerId: Int
    let text: String
    let date: Date
    let sizes: PhotoSizes
    let width: Int?
    let height: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case albumId = "album_id"
        case ownerId = "owner_id"
        case text
        case date
        case sizes
        case width
        case height
    }
}
