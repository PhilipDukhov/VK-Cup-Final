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
        completion: @escaping (Result<GroupAndProducts, BaseApiManager.Error>) -> Void
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
    
    func getGroupAndProducts(
        groupId: String,
        completion: @escaping (Result<GroupAndProducts, BaseApiManager.Error>) -> Void
    ) {
        baseApiManager.sendHandleAndParseFirst(
            VK.API.Custom.execute(
                code: """
                    var group = API.groups.getById({"group_id": "\(groupId)"})[0];
                    return [{
                        "group": group,
                        "products": API.market.get({
                                    "owner_id": "-" + group.id,
                                })
                    }];
                """),
            container: .response,
            completion: completion
        )
    }
}
