//
//  MarketListLeaf.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation

enum MarketListLeaf {
    struct Model {
        var selectedCountry: Country?
        var selectedCity: City?
        var marketQuery: String = ""
        var groups: [Group] = []
        var error: Error?
        
        let apiManager = VkApiManager()
    }
    
    enum Msg {
        case setError(Error)
        case clearError
        case requestUserInfo
        case updateUserInfo(UserInfo)
        case updateGroups([Group])
        case updateMarketQuery(String)
        case requestMarketGroupsUpdate
    }
    
    struct Props {
        let cityName: String?
        let marketQuery: String
        let groups: [Group]
        var error: Error?
    }
    
    static let initial = { () -> (Model, Effect<Msg>) in
        (Model(), { $0(.requestUserInfo) })
    }
    
    static let update = { (msg: Msg, model: Model) -> (Model, Effect<Msg>?) in
        var newModel = model
        var effect: Effect<Msg>?
        switch msg {
        case .requestUserInfo:
            effect = model.getCurrentUserInfoEffect
            
        case .updateUserInfo(let userInfo):
            newModel.selectedCountry = userInfo.country
            newModel.selectedCity = userInfo.city
            effect = { $0(.requestMarketGroupsUpdate) }
            
        case .requestMarketGroupsUpdate:
            guard let country = model.selectedCountry else {
                effect = model.getDefaultCountryEffect
                break
            }
            guard let city = model.selectedCity else {
                effect = model.getDefaultCityEffect(country: country)
                break
            }
            effect = model.updateMarketGroupListEffect(
                query: model.marketQuery,
                city: city
            )
            
        case .setError(let error):
            newModel.error = error
            
        case .clearError:
            newModel.error = nil
            
        case .updateGroups(let groups):
            newModel.groups = groups
            
        case .updateMarketQuery(let marketQuery):
            newModel.marketQuery = marketQuery
        }
        return (newModel, effect)
    }
    
    static let view = { (model: Model) -> Props in
        .init(
            cityName: model.selectedCity?.title,
            marketQuery: model.marketQuery,
            groups: model.groups,
            error: model.error
        )
    }
}

extension MarketListLeaf.Model {
    fileprivate var getCurrentUserInfoEffect: Effect<MarketListLeaf.Msg> {
        { dispatch in
            apiManager.getCurrentUserLocationInfo { result in
                result.get(
                    errorDispatch: dispatch
                ) { userInfo in
                    dispatch(.updateUserInfo(userInfo))
                }
            }
        }
    }
    
    fileprivate var getDefaultCountryEffect: Effect<MarketListLeaf.Msg> {
        { dispatch in
            apiManager.getDefaultCountry { result in
                result.get(
                    errorDispatch: dispatch
                ) { country in
                    dispatch(
                        .updateUserInfo(
                            .init(
                                country: country,
                                city: nil
                            )
                        )
                    )
                }
            }
        }
    }
    
    fileprivate func getDefaultCityEffect(
        country: Country
    ) -> Effect<MarketListLeaf.Msg> {
        { dispatch in
            apiManager.getDefaultCity(
                country: country
            ) { result in
                result.get(
                    errorDispatch: dispatch
                ) { city in
                    dispatch(
                        .updateUserInfo(
                            .init(
                                country: country,
                                city: city
                            )
                        )
                    )
                }
            }
        }
    }
    
    fileprivate func updateMarketGroupListEffect(
        query: String,
        city: City
    ) -> Effect<MarketListLeaf.Msg> {
        { dispatch in
            apiManager.getMarketGroups(
                query: query,
                city: city
            ) { result in
                result.get(
                    errorDispatch: dispatch
                ) { groups in
                    dispatch(
                        .updateGroups(groups)
                    )
                }
            }
        }
    }
}

extension Result {
    func get(
        errorDispatch: Dispatch<MarketListLeaf.Msg>,
        successCompletion: (Success) -> Void)
    {
        switch self {
        case .success(let value):
            successCompletion(value)
            
        case .failure(let error):
            errorDispatch(.setError(error))
        }
    }
}
