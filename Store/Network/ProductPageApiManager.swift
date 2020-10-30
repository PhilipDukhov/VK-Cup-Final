//
//  ProductPageApiManager.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import Foundation
import SwiftyVK

class ProductPageApiManager {
    private let baseApiManager = BaseApiManager()
    
    func setFavorite(
        product: Product,
        favorite: Bool,
        completion: @escaping (Result<Void, BaseApiManager.Error>) -> Void
    ) {
        VK.API.Custom.setFave(
            favorite,
            ["owner_id": product.ownerId,
             "id": product.id,
            ].stringify
        ).onSuccess { data in
            guard
                let json = try? JSONSerialization.jsonObject(with: data),
                let dict = json as? [String: Any],
                dict["response"] != nil
            else {
                completion(.failure(.emptyResponse))
                return
            }
            completion(.success(()))
        }
        .onError {
            completion(
                .failure(
                    .with(vkError: $0)
                )
            )
        }
        .send()
    }
}

extension VK.API.Custom {
    static func setFave(
        _ like: Bool,
        _ parameters: SwiftyVK.RawParameters
    ) -> CustomMethod {
        method(
            name: "fave.\(like ? "addProduct" : "removeProduct")",
            parameters: parameters
        )
    }
}
