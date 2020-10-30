//
//  ChooseCityLeaf.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import Foundation

private typealias Msg = ChooseCityLeaf.Msg
private typealias Model = ChooseCityLeaf.Model

class ChooseCityLeaf {
    struct Model {
        struct InitialInfo {
            let userInfo: UserInfo
            let selectedCountry: Country
            let selectedCity: City
        }
        
        let initialInfo: InitialInfo
        var cities: [City]?
        var error: Error?
        
        let apiManager = ChooseCityApiManager()
    }
    
    enum Msg {
        case setError(Error?)
        case requestCitiesListUpdate
        case updateCitiesList([City])
    }
    
    struct Props {
        let cities: [City]
        let selectedCity: City
        let error: Error?
    }
    
    static func initial(
        initialInfo: Model.InitialInfo
    ) -> (() -> (Model, Effect<Msg>?))
    {
        return {
            (Model(initialInfo: initialInfo),
             { $0(.requestCitiesListUpdate) })
        }
    }

    static let update = { (msg: Msg, model: Model) -> (Model, Effect<Msg>?) in
        var newModel = model
        var effect: Effect<Msg>?
        switch msg {
        case .setError(let error):
            newModel.error = error
        
        case .requestCitiesListUpdate:
            effect = model.getCurrentUserInfoEffect(
                country: model.initialInfo.selectedCountry
            )
            
        case .updateCitiesList(let cities):
            newModel.cities = cities
        }
        return (newModel, effect)
    }
    
    // user doesn't need to know type Runtime,
    // he only needs to store this class while rendering needed
    static func runtime(
        initialInfo: Model.InitialInfo,
        render: @escaping Runtime<Model, Msg>.Render
    ) -> Any {
        Runtime(
            initial: initial(initialInfo: initialInfo),
            update: update,
            render: render
        )
    }
}

extension Model: ModelViewable {
    var buildProps: ChooseCityLeaf.Props {
        var cities = (self.cities ?? [])
        cities.insertOrMove(
            initialInfo.selectedCity,
            at: 0
        )
        initialInfo.userInfo.city.map {
            cities.insertOrMove($0, at: 0)
        }
        return .init(
            cities: cities,
            selectedCity: initialInfo.selectedCity,
            error: error
        )
    }
}

extension Model {
    fileprivate func getCurrentUserInfoEffect(
        country: Country
    ) -> Effect<Msg>  {
        { dispatch in
            apiManager.getCities(country: country) { result in
                result.get(
                    errorDispatch: dispatch
                ) { cities in
                    dispatch(.updateCitiesList(cities))
                }
            }
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
