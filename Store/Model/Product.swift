//
//  Product.swift
//  Store
//
//  Created by Philip Dukhov on 10/27/20.
//

import Foundation

struct Product: Codable, Identifiable {
    let id: Int
    let ownerId: Int
    let title: String
    let description: String
    let isFavorite: Bool
    let photos: [Photo]
    let price: Price
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case title
        case description
        case isFavorite = "is_favorite"
        case photos
        case price
    }
    
    var link: URL {
        URL(string: "https://vk.com/market\(ownerId)?w=product\(ownerId)_\(id)")!
    }
}
