//
//  UserInfo.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation

class UserInfo: ModelType {
    enum CodingKeys: String, CodingKey {
        case country
        case city
    }
    
    required convenience init(
        from decoder: Decoder
    ) throws {
        self.init(context: try decoder.managedObjectContext())
        let container = try decoder.container(keyedBy: CodingKeys.self)
        city = try? container.decode(City.self, forKey: .city)
        country = try? container.decode(Country.self, forKey: .country)
    }
    
    var id: String { "\(country?.id ?? -1)|\(city?.id ?? -1)" }
}
