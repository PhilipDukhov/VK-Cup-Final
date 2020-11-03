//
//  ChooseCityLeaf.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import Foundation
import CoreData

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
        
        let apiManager: ChooseCityApiManager
        
        let managedObjectContext: NSManagedObjectContext
        
        init(
            initialInfo: InitialInfo,
            context: NSManagedObjectContext
        ) {
            self.initialInfo = initialInfo
            managedObjectContext = context
            apiManager = .init(context: context)
        }
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
        initialInfo: Model.InitialInfo,
        context: NSManagedObjectContext
    ) -> (() -> (Model, Effect<Msg>?))
    {
        return {
            (Model(initialInfo: initialInfo, context: context),
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
        context: NSManagedObjectContext,
        render: @escaping Runtime<Model, Msg>.Render
    ) -> Any {
        Runtime(
            initial: initial(initialInfo: initialInfo, context: context),
            update: update,
            render: render
        )
    }
}

extension Model: ModelViewable {
    var buildProps: ChooseCityLeaf.Props {
        return .init(
            cities: cities ?? [],
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
            updateSortedCities(dispatch)
            apiManager.getCities(country: country) { result in
                result.get(
                    errorDispatch: dispatch
                ) { _ in
                    updateSortedCities(dispatch)
                }
            }
        }
    }
    
    fileprivate func updateSortedCities(
        _ dispatch: @escaping Dispatch<Msg>
    ) {
        managedObjectContext.perform {
            let sortDescriptors = [
                NSSortDescriptor(
                    key: #keyPath(City.id),
                    ascending: true
                ),
            ]
            var cities: [City] = managedObjectContext
                .get(
                    sortDescriptors: sortDescriptors
                )
            cities = cities.enumerated().filter {
                $0.offset == 0 || $0.element.id != cities[$0.offset - 1].id
            }.map { $0.element }
            cities.insertOrMove(
                initialInfo.selectedCity,
                at: 0
            )
            initialInfo.userInfo.city.map {
                cities.insertOrMove($0, at: 0)
            }
            dispatch(
                .updateCitiesList(
                    cities
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
