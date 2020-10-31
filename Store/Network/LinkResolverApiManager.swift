//
//  LinkResolverApiManager.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import Foundation
import SwiftyVK

class LinkResolverApiManager {
    private let baseApiManager = BaseApiManager()
    
    func getProduct(
        productId: String,
        completion: @escaping (Result<Product, BaseApiManager.Error>) -> Void
    ) {
        baseApiManager.sendHandleAndParseFirst(
            VK.API.Market.getById([
                .itemIds: productId,
                .extended: 1,
            ].stringify),
            container: .items,
            completion: completion
        )
    }
    
    func getGroupIfHasMarket(
        groupId: Int,
        completion: @escaping (Result<Group, BaseApiManager.Error>) -> Void
    ) {
        baseApiManager.sendHandleAndParseFirst(
            // С помощью VKScript загружаем группу только
            // в том случае, если у нее не пустой магазин
            VK.API.Custom.remote(
                method: "getGroupIfHasMarket",
                parameters: [
                    "groupId": groupId
                ].stringify
            ),
            container: .response,
            completion: completion
        )
    }
}
