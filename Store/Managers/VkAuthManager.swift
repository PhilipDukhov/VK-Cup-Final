//
//  VkAuthManager.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation
import SwiftyVK

class VkAuthManager {
    func authorize(
        completion: @escaping (Result<Void, VkApiManager.Error>) -> Void
    ) {
        let success = { (tokenInfo: [String: String]) in
            guard tokenInfo["user_id"] != nil else {
                completion(.failure(.emptyResponse))
                return
            }
            completion(.success(()))
        }
        VK.sessions.default.logIn(
            onSuccess: success) { error in
            switch error {
            case .sessionAlreadyAuthorized(let session) where session.accessToken != nil:
                success(session.accessToken!.info)
                
            default:
                completion(.failure(.vkError(error)))
            }
        }
    }
}
