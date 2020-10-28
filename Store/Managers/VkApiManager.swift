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
    private enum ResponseContainer {
        case items
        case response
    }
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
    
    // MARK: public requests
    
    func getCurrentUserLocationInfo(
        completion: @escaping (Result<UserInfo, Error>) -> Void
    ) {
        sendHandleAndParseFirst(
            VK.API.Users.get([
                .fields: "city,country",
            ]),
            container: .response,
            completion: completion
        )
    }
    
    func getMarketGroups(
        query: String,
        city: City,
        completion: @escaping (Result<[Group], Error>) -> Void
    ) {
        sendHandleAndParse(
            VK.API.Groups.search(.stringifyValues([
                .q: query.isEmpty ? "Music" : query,
                .market: 1,
                .cityId: city.id,
            ])),
            container: .items,
            completion: completion
        )
    }
    
    func getDefaultCountry(
        completion: @escaping (Result<Country, Error>) -> Void
    ) {
        sendHandleAndParseFirst(
            VK.API.Database.getCountries([
                .code: "RU",
            ]),
            container: .items,
            completion: completion
        )
    }
    
    func getCities(
        country: Country,
        completion: @escaping (Result<[City], Error>) -> Void
    ) {
        sendHandleAndParse(
            VK.API.Database.getCities(.stringifyValues([
                .countryId: country.id,
            ])),
            container: .items,
            completion: completion
        )
    }
    
    func getDefaultCity(
        country: Country,
        completion: @escaping (Result<City, Error>) -> Void
    ) {
        sendHandleAndParseFirst(
            VK.API.Database.getCities(.stringifyValues([
                .countryId: country.id,
                .count: "1"
            ])),
            container: .items,
            completion: completion
        )
    }
    
    func listProducts(
        group: Group,
        completion: @escaping (Result<[Product], Error>) -> Void
    ) {
        sendHandleAndParse(
            VK.API.Market.get([
                .ownerId: "-\(group.id)",
            ]),
            container: .items,
            completion: completion
        )
    }
    
    // MARK: Parsing helpers
    
    private func sendHandleAndParse<R: Codable>(
        _ apiMethod: APIMethod,
        container: ResponseContainer,
        completion: @escaping (Result<[R], Error>) -> Void
    ) {
        apiMethod.onSuccess { [weak self] data in
            guard let strongSelf = self else { return }
            let result: [R]
            switch container {
            case .items:
                result = try strongSelf.decoder.decode(
                    ResponseItems<R>.self,
                    from: data
                ).items
                
            case .response:
                result = try strongSelf.decoder.decode(
                    [R].self,
                    from: data
                )
            }
            completion(.success(result))
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
    
    private func sendHandleAndParseFirst<R: Codable>(
        _ apiMethod: APIMethod,
        container: ResponseContainer,
        completion: @escaping (Result<R, Error>) -> Void
    ) {
        sendHandleAndParse(
            apiMethod,
            container: container
        ) { [weak self] (result: Result<[R], Error>) in
            self.map { completion($0.flatMapFirst(from: result)) }
        }
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
}

extension SwiftyVK.Parameters {
    // no need to wrap values to string
    fileprivate static func stringifyValues(_ anyValueDict: [Key: Any]) -> Self {
        anyValueDict
            .reduce(into: [:]) { $0[$1.0] = "\($1.1)" }
    }
}
