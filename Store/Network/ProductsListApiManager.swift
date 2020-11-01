//
//  ProductsListApiManager.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import Foundation
import SwiftyVK
import CoreData

class ProductsListApiManager {
    private let baseApiManager: BaseApiManager
    
    init(context: NSManagedObjectContext) {
        baseApiManager = BaseApiManager(context: context)
    }
    
    func getProducts(
        group: Group,
        completion: @escaping (Result<[Product], BaseApiManager.Error>) -> Void
    ) {
        baseApiManager.sendHandleAndParse(
            VK.API.Market.get([
                .ownerId: "-\(group.id)",
                .extended: 1,
            ].stringify),
            container: .items,
            completion: completion
        )
    }
}
