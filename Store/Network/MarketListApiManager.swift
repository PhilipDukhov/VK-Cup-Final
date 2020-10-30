//
//  MarketListApiManager.swift
//  Store
//
//  Created by Philip Dukhov on 10/27/20.
//

import Foundation
import SwiftyVK

class MarketListApiManager {
    private let baseApiManager = BaseApiManager()
    
    func getCurrentUserLocationInfo(
        completion: @escaping (Result<UserInfo, BaseApiManager.Error>) -> Void
    ) {
        baseApiManager.sendHandleAndParseFirst(
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
        completion: @escaping (Result<[Group], BaseApiManager.Error>) -> Void
    ) {
        baseApiManager.sendHandleAndParse(
            VK.API.Custom.execute(
                code: """
                    var groups = API.groups.search({
                        "q": "\(query.isEmpty ? "Мотоаксессуары" : query)",
                        "market": 1,
                        "cityId": \(city.id),
                    }).items;
                    var filteredGroups = [];
                    var i = 0;

                    while (i!=groups.length) {
                        if (API.market.get({
                                    "ownerId": "-" + groups[i].id,
                                    "count": 0,
                                }).count!=0)
                        {
                            filteredGroups.push(groups[i]);
                        }
                        i=i+1;
                    }
                    return filteredGroups;
                """),
            container: .response,
            completion: completion
        )
    }
    
    func getDefaultCountry(
        completion: @escaping (Result<Country, BaseApiManager.Error>) -> Void
    ) {
        baseApiManager.sendHandleAndParseFirst(
            VK.API.Database.getCountries([
                .code: "RU",
            ]),
            container: .items,
            completion: completion
        )
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
    
    func getDefaultCity(
        country: Country,
        completion: @escaping (Result<City, BaseApiManager.Error>) -> Void
    ) {
        baseApiManager.sendHandleAndParseFirst(
            VK.API.Database.getCities([
                .countryId: country.id,
                .count: "1"
            ].stringify),
            container: .items,
            completion: completion
        )
    }
    
    func localize(
        city: City,
        completion: @escaping (Result<City, BaseApiManager.Error>) -> Void
    ) {
        let morpherURL = URL(string: "https://ws3.morpher.ru/russian/declension")!
        let request = URLRequest(
            url: morpherURL.appendingQueryParameters(
                ["s": "\(city.title)",
                 "format": "json"]
            ),
            cachePolicy: .returnCacheDataElseLoad
        )
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data),
                let dict = json as? [String: Any],
                let inflectedTitle = dict["П"] as? String
            else {
                completion(.failure(.emptyResponse))
                return
            }
            completion(
                .success(
                    City(
                        city: city,
                        inflectedTitle: inflectedTitle
                    )
                )
            )
            
        }.resume()
    }
}
