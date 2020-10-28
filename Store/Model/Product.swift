//
//  Product.swift
//  Store
//
//  Created by Philip Dukhov on 10/27/20.
//

import Foundation

struct Product: Codable {
    let id: Int
    let title: String
    let description: String
    let isFavorite: String
    let photos: [Photo]
    let price: Price
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case isFavorite = "is_favorite"
        case photos
        case price
    }
}
