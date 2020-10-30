//
//  City.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation

struct City: Codable, Identifiable {
    let id: Int
    let title: String
    
    let inflectedTitle: String?
    
    init(city: City, inflectedTitle: String) {
        id = city.id
        title = city.title
        self.inflectedTitle = inflectedTitle
    }
}
