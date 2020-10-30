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
            VK.API.Custom.execute(
                code: """
                    var group = API.groups.getById({
                        "group_id": "\(groupId)",
                        "fields": "market"
                    })[0];
                    if (group.market.enabled==0||
                        API.market.get({
                            "owner_id": -group.id,
                            "count": 0,
                        }).count==0
                    ) {
                        return null;
                    }
                    return [group];
                """),
            container: .response,
            completion: completion
        )
    }
}
