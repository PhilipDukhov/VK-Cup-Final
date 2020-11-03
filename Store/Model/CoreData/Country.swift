//
//  Country.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation

class Country: ModelType {
    enum CodingKeys: String, CodingKey {
        case id
        case title
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
        title = try container.decode(String.self, forKey: .title)
    }
}
