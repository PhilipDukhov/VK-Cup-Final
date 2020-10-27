//
//  VkApiManager.swift
//  Store
//
//  Created by Philip Dukhov on 10/27/20.
//

import Foundation
import SwiftyVK

class VkApiManager {
    enum Error: Swift.Error {
        case emptyResponse
        case urlRequestError(Swift.Error)
        
        case vkError(VKError)
        
        static func with(vkError: VKError) -> Self {
            switch vkError {
            case .urlRequestError(let error):
                return .urlRequestError(error)
                
            default:
                return .vkError(vkError)
            }
        }
    }
    
    private var userId: String?
    private var userLocationInfo: UserLocationInfo?
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
    
    // MARK: Auth
    
    func authorize(
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let success = { [weak self] (tokenInfo: [String: String]) in
            guard let userId = tokenInfo["user_id"] else {
                completion(.failure(.emptyResponse))
                return
            }
            self?.userId = userId
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
    
    // MARK: public requests
    
    func listMarketGroups(
        query: String,
        cityId: String? = nil,
        completion: @escaping (Result<[Group], Error>) -> Void
    ) {
        solveCityId(selectedId: cityId) { [self] result in
            switch result {
            case .success(let cityId):
                sendHandleAndParse(
                    VK.API.Groups.search([
                        .q: query,
                        .market: "1",
                        .cityId: cityId
                    ]),
                    completion: completion
                )
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func listCities(
        completion: @escaping (Result<[City], Error>) -> Void
    ) {
        solveUserLocationInfo { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let userLocationInfo):
                self?.sendHandleAndParse(
                    VK.API.Database.getCities([
                        .countryId: userLocationInfo.county.id,
                    ]),
                    completion: completion
                )
            }
        }
    }
    
    func listProducts(
        group: Group,
        completion: @escaping (Result<[Product], Error>) -> Void
    ) {
        sendHandleAndParse(
            VK.API.Market.get([
                .ownerId: "-\(group.id)",
            ]),
            completion: completion
        )
    }
         
    // MARK: Request helpers
    
    private func solveCityId(
        selectedId: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        if let cityId = selectedId {
            completion(.success(cityId))
        } else {
            solveUserLocationInfo { result in
                completion(result.map { $0.city.id })
            }
        }
    }
    
    private func solveUserLocationInfo(
        completion: @escaping (Result<UserLocationInfo, Error>) -> Void
    ) {
        if let userLocationInfo = userLocationInfo {
            completion(.success(userLocationInfo))
        } else {
            getCurrentUserLocationInfo { [weak self] result in
                self?.userLocationInfo = try? result.get()
                completion(result)
            }
        }
    }
    
    // MARK: Private requests
    
    private func getCurrentUserLocationInfo(
        completion: @escaping (Result<UserLocationInfo, Error>) -> Void
    ) {
        sendHandleAndParse(
            VK.API.Users.get([
                .fields: "city,country",
            ])
        ) { [weak self] (result: Result<[UserLocationInfo], Error>) in
            self.map { completion($0.flatMapFirst(from: result)) }
        }
    }
    
    // MARK: Parsing helpers
    
    private func sendHandleAndParse<R: Codable>(
        _ apiMethod: APIMethod,
        completion: @escaping (Result<[R], Error>) -> Void
    ) {
        apiMethod.onSuccess { [weak self] data in
            guard let strongSelf = self else { return }
            completion(
                .success(
                    try strongSelf.decoder.decode(
                        ServerItems<R>.self,
                        from: data
                    ).items
                )
            )
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
    
    private func flatMapFirst<R>(
        from result: Result<[R], Error>
    ) -> Result<R, Error> {
        result.flatMap {
            guard let value = $0.first else {
                return .failure(.emptyResponse)
            }
            return .success(value)
        }
    }
    
    private struct UserLocationInfo: Codable {
        let city: City
        let county: Country
    }
}
