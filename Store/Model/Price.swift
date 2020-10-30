//
//  Price.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation

class Price: Codable {
    struct Currency: Codable, Identifiable {
        let id: Int
        let name: String
    }
    
    let amount: String
    let currency: Currency
    let text: String
}
