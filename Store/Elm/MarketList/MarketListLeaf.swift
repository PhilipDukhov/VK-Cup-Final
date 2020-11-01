//
//  MarketListLeaf.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import CoreData

private typealias Msg = MarketListLeaf.Msg
private typealias Model = MarketListLeaf.Model

enum MarketListLeaf {
    struct Model {
        var userInfo: UserInfo?
        var selectedCountry: Country?
        var selectedCity: City?
        var marketQuery: String = "Одежда"
        var groups: [Group] = []
        var error: Error?
        
        var navigationMsg: NavigationMsg?
        
        let apiManager: MarketListApiManager
        let managedObjectContext: NSManagedObjectContext
        
        init(context: NSManagedObjectContext) {
            managedObjectContext = context
            apiManager = .init(context: context)
        }
    }
    
    enum Msg {
        case setError(Error?)
        case requestUserInfo
        case updateUserInfo(UserInfo)
        case updateCountry(Country)
        case updateCity(City)
        case updateCityFromPicker(City)
        case updateGroups([Group])
        case updateMarketQuery(String)
        case requestMarketGroupsUpdate
        case chooseCity
        case clearNavigationMsg
        case selectGroup(Group)
    }
    
    enum NavigationMsg {
        case chooseCity(ChooseCityLeaf.Model.InitialInfo)
        case selectGroup(ProductsListLeaf.Model.InitialInfo)
    }
    
    struct Props {
        let city: City?
        let marketQuery: String
        let groups: [Group]
        let navigationMsg: NavigationMsg?
        let error: Error?
    }
    
    static func initial(
        context: NSManagedObjectContext
    ) -> (() -> (Model, Effect<Msg>?))
    {
        return {
            (Model(context: context),
            { $0(.requestUserInfo) })
        }
    }
    
    static let update = { (msg: Msg, model: Model) -> (Model, Effect<Msg>?) in
        var newModel = model
        var effect: Effect<Msg>?
        switch msg {
        case .requestUserInfo:
            effect = model.getCurrentUserInfoEffect
            
        case .updateUserInfo(let userInfo):
            newModel.userInfo = userInfo
            newModel.selectedCountry = userInfo.country
            newModel.selectedCity = userInfo.city
            newModel.initCountryAndCityFromUserDefaultsIfNeeded()
            effect = { $0(.requestMarketGroupsUpdate) }
            
        case .updateCountry(let country):
            newModel.selectedCountry = country
            UserDefaults.standard.setValue(
                country.id,
                forKey: .selectedCountryIdKey
            )
            effect = { $0(.requestMarketGroupsUpdate) }
            
        case .updateCityFromPicker(let city):
            newModel.navigationMsg = nil
            newModel.groups = []
            fallthrough
            
        case .updateCity(let city):
            if model.selectedCity?.id != city.id {
                newModel.groups = []
            }
            newModel.selectedCity = city
            UserDefaults.standard.setValue(
                city.id,
                forKey: .selectedCityIdKey
            )
            effect = model.afterCityUpdatedEffect(city: city)
            
        case .requestMarketGroupsUpdate:
            guard let city = model.selectedCity else {
                guard let country = model.selectedCountry else {
                    effect = model.getDefaultCountryEffect
                    break
                }
                effect = model.getDefaultCityEffect(country: country)
                break
            }
            effect = model.updateMarketGroupListEffect(
                query: model.marketQuery,
                city: city
            )
            
        case .setError(let error):
            newModel.error = error
            
        case .updateGroups(let groups):
            newModel.groups = groups
            
        case .updateMarketQuery(let marketQuery):
            newModel.marketQuery = marketQuery
        case .chooseCity:
            newModel.navigationMsg = .chooseCity(
                .init(
                    userInfo: model.userInfo!,
                    selectedCountry: model.selectedCountry!,
                    selectedCity: model.selectedCity!
                )
            )
            
        case .selectGroup(let group):
            newModel.navigationMsg = .selectGroup(
                .init(
                    group: group
                )
            )
        case .clearNavigationMsg:
            newModel.navigationMsg = nil
        }
        return (newModel, effect)
    }
    
    static func runtime(
        context: NSManagedObjectContext,
        render: @escaping Runtime<Model, Msg>.Render
    ) -> Any {
        Runtime(
            initial: initial(context: context),
            update: update,
            render: render
        )
    }
}

extension Model: ModelViewable {
    var buildProps: MarketListLeaf.Props {
        .init(
            city: selectedCity,
            marketQuery: marketQuery,
            groups: groups,
            navigationMsg: navigationMsg,
            error: error
        )
    }
}

extension Model {
    fileprivate mutating func initCountryAndCityFromUserDefaultsIfNeeded(
    ) {
        databaseQueue.sync {
            guard
                selectedCountry == nil,
                let countryId = UserDefaults.standard.string(
                    forKey: .selectedCountryIdKey
                ), let country = (managedObjectContext
                                    .get(
                                        predicate: NSPredicate(
                                            format: "id == '\(countryId)'"
                                        ),
                                        fetchLimit: 1
                                    ) as [Country]).first
            else { return }
            selectedCountry = country
            guard let cityId = UserDefaults.standard.string(
                forKey: .selectedCountryIdKey
            ), let city = (managedObjectContext
                            .get(
                                predicate: NSPredicate(
                                    format: "id == '\(cityId)'"
                                ),
                                fetchLimit: 1
                            ) as [City]).first
            else { return }
            selectedCity = city
        }
    }
    
    fileprivate var getCurrentUserInfoEffect: Effect<Msg> {
        { dispatch in
            databaseQueue.async {
                if let userInfo = (
                    managedObjectContext
                        .get(fetchLimit: 1) as [UserInfo]
                ).first
                {
                    dispatch(.updateUserInfo(userInfo))
                } else {
                    apiManager.getCurrentUserLocationInfo { result in
                        result.get(
                            errorDispatch: dispatch
                        ) { userInfo in
                            dispatch(.updateUserInfo(userInfo))
                        }
                    }
                }
            }
        }
    }
    
    fileprivate var getDefaultCountryEffect: Effect<Msg> {
        { dispatch in
            apiManager.getDefaultCountry { result in
                result.get(
                    errorDispatch: dispatch
                ) { country in
                    dispatch(.updateCountry(country))
                }
            }
        }
    }
    
    fileprivate func getDefaultCityEffect(
        country: Country
    ) -> Effect<Msg> {
        { dispatch in
            apiManager.getDefaultCity(
                country: country
            ) { result in
                result.get(
                    errorDispatch: dispatch
                ) { city in
                    dispatch(.updateCity(city))
                }
            }
        }
    }
    
    fileprivate func afterCityUpdatedEffect(
        city: City
    ) -> Effect<Msg> {
        { dispatch in
            dispatch(.requestMarketGroupsUpdate)
            if city.inflectedTitle == nil {
                apiManager.localize(city: city) { result in
                    guard let city = try? result.get() else { return }
                    dispatch(.updateCity(city))
                }
            }
        }
    }
    
    fileprivate func updateMarketGroupListEffect(
        query: String,
        city: City
    ) -> Effect<Msg> {
        { dispatch in
            updateSortedGroups(
                query: query,
                city: city,
                dispatch: dispatch
            )
            apiManager.getMarketGroups(
                query: query,
                city: city
            ) { result in
                result.get(
                    errorDispatch: dispatch
                ) { _ in
                    updateSortedGroups(
                        query: query,
                        city: city,
                        dispatch: dispatch
                    )
                }
            }
        }
    }
    
    fileprivate func updateSortedGroups(
        query: String,
        city: City,
        dispatch: @escaping Dispatch<Msg>
    ) {
        let predicate = NSPredicate(
            format: "(name CONTAINS[c] '\(query)') AND (city.id == '\(city.id)')"
        )
        let sortDescriptors = [
            NSSortDescriptor(
                key: #keyPath(Group.id),
                ascending: true
            ),
        ]
        databaseQueue.async {
            dispatch(
                .updateGroups(
                    managedObjectContext
                        .get(
                            predicate: predicate,
                            sortDescriptors: sortDescriptors
                        )
                )
            )
        }
    }
}

extension Result {
    fileprivate func get(
        errorDispatch: Dispatch<Msg>,
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

extension String {
    static let selectedCityIdKey = "selectedCityId"
    static let selectedCountryIdKey = "selectedCountryId"
}
