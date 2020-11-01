//
//  ChooseCityApiManager.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import Foundation
import SwiftyVK
import CoreData

class ChooseCityApiManager {
    private let baseApiManager: BaseApiManager
    
    init(context: NSManagedObjectContext) {
        baseApiManager = BaseApiManager(context: context)
    }
    
    func getCities(
        country: Country,
        completion: @escaping (Result<[City], BaseApiManager.Error>) -> Void
    ) {
        baseApiManager.sendHandleAndParse(
            VK.API.Database.getCities([
                .countryId: country.id,
            ].stringify),
            container: .items,
            completion: completion
        )
    }
}
