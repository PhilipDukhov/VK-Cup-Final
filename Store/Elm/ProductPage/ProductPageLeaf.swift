//
//  ProductPageLeaf.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import Foundation

private typealias Msg = ProductPageLeaf.Msg
private typealias Model = ProductPageLeaf.Model

class ProductPageLeaf {
    struct Model {
        struct InitialInfo {
            let product: Product
        }
        
        let initialInfo: InitialInfo
        var favorite: Bool?
        var error: Error?
        
        let apiManager = ProductPageApiManager()
    }
    
    enum Msg {
        case setError(Error?)
        case setFavorite(Bool)
        case revertFavorite
    }
    
    struct Props {
        let isFavorite: Bool
        let error: Error?
    }
    
    static func initial(
        initialInfo: Model.InitialInfo
    ) -> (() -> (Model, Effect<Msg>?))
    {
        return {
            (Model(initialInfo: initialInfo),
             nil)
        }
    }
    
    static let update = { (msg: Msg, model: Model) -> (Model, Effect<Msg>?) in
        var newModel = model
        var effect: Effect<Msg>?
        switch msg {
        case .setError(let error):
            newModel.error = error
            
        case .revertFavorite:
            newModel.favorite = nil
            
        case .setFavorite(let isFavorite):
            newModel.favorite = isFavorite
            effect = model.setFavorite(
                product: model.initialInfo.product,
                favorite: isFavorite
            )
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
    var buildProps: ProductPageLeaf.Props {
        .init(
            isFavorite: favorite ?? initialInfo.product.isFavorite,
            error: error
        )
    }
}

extension Model {
    fileprivate func setFavorite(
        product: Product,
        favorite: Bool
    ) -> Effect<Msg>  {
        { dispatch in
            apiManager.setFavorite(
                product: product,
                favorite: favorite
            ) { result in
                if case .failure(let error) = result {
                    print(error)
                    dispatch(.revertFavorite)
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
