//
//  Product.swift
//  Store
//
//  Created by Philip Dukhov on 10/27/20.
//

import Foundation
import CoreData

class Product: ModelType {
//    let id: Int
//    let ownerId: Int
//    let title: String
//    let description: String
//    let isFavorite: Bool
//    let photos: [Photo]
//    let c: Price
    
    var link: URL {
        URL(string: "https://vk.com/market\(ownerId)?w=product\(ownerId)_\(id)")!
    }
    var photos: [Photo] {
        // swiftlint:disable:next force_try
        try! decoder.decode([Photo].self, from: photosData!)
    }
    var price: Price {
        // swiftlint:disable:next force_try
        try! decoder.decode(Price.self, from: priceData!)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case title
        case productDescription = "description"
        case isFavorite = "is_favorite"
        case photosData = "photos"
        case priceData = "price"
    }
    
    required convenience init(
        from decoder: Decoder
    ) throws {
        let context = try decoder.managedObjectContext()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            orGetFirst: try container.decode(Int64.self, forKey: .id),
            context: context
        )
        ownerId = try container.decode(Int64.self, forKey: .ownerId)
        title = try container.decode(String.self, forKey: .title)
        productDescription = try container.decode(String.self, forKey: .productDescription)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        photosData = try encoder.encode(try container.decode([Photo].self, forKey: .photosData))
        priceData = try encoder.encode(try container.decode(Price.self, forKey: .priceData))
    }
}

private let encoder = JSONEncoder()
private let decoder = JSONDecoder()
