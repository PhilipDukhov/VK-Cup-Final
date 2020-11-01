//
//  Group.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation
import CoreData

class Group: ModelType {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case city
        case photo50 = "photo_50"
        case photo100 = "photo_100"
        case photo200 = "photo_200"
        case isClosed = "is_closed"
    }
    
    var photoSizes: PhotoSizes {
        let sizes = [
            50: photo50,
            100: photo100,
            200: photo200,
        ].map {
            PhotoSize(
                type: .custom,
                src: $0.value!,
                width: $0.key,
                height: $0.key
            )
        }
        return PhotoSizes(sizes: sizes)
    }
    
    var visibility: Visibility {
        Visibility(rawValue: .init(isClosed))!
    }
    
    required convenience init(
        from decoder: Decoder
    ) throws {       
        self.init(context: try decoder.managedObjectContext())
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        photo50 = try container.decode(String.self, forKey: .photo50)
        photo100 = try container.decode(String.self, forKey: .photo100)
        photo200 = try container.decode(String.self, forKey: .photo200)
        isClosed = try container.decode(Int16.self, forKey: .isClosed)        
        city = try container.decode(City.self, forKey: .city)
    }
}
