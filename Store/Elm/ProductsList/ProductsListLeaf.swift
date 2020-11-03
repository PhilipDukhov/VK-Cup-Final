//
//  ProductsListLeaf.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import Foundation
import CoreData

private typealias Msg = ProductsListLeaf.Msg
private typealias Model = ProductsListLeaf.Model

class ProductsListLeaf {
    struct Model {
        struct InitialInfo {
            let group: Group
        }
        
        let initialInfo: InitialInfo
        var products: [Product] = []
        var error: Error?
        
        var navigationMsg: NavigationMsg?
        
        let apiManager: ProductsListApiManager
        
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
        case requestProductsUpdate
        case updateProductList([Product])
        case selectProduct(Product)
        case clearNavigationMsg
    }
    
    enum NavigationMsg {
        case selectProduct(ProductPageLeaf.Model.InitialInfo)
    }
    
    struct Props {
        let products: [Product]
        let navigationMsg: NavigationMsg?
        let error: Error?
    }
    
    static func initial(
        initialInfo: Model.InitialInfo,
        context: NSManagedObjectContext
    ) -> (() -> (Model, Effect<Msg>?))
    {
        return {
            (Model(initialInfo: initialInfo, context: context),
             { $0(.requestProductsUpdate) })
        }
    }
    
    static let update = { (msg: Msg, model: Model) -> (Model, Effect<Msg>?) in
        var newModel = model
        var effect: Effect<Msg>?
        switch msg {
        case .setError(let error):
            newModel.error = error
            
        case .clearNavigationMsg:
            newModel.navigationMsg = nil
            
        case .requestProductsUpdate:
            effect = model.getProductListEffect(group: model.initialInfo.group)
            
        case .updateProductList(let products):
            newModel.products = products
        case .selectProduct(let product):
            newModel.navigationMsg = .selectProduct(
                .init(product: product)
            )
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
    var buildProps: ProductsListLeaf.Props {
        .init(
            products: products,
            navigationMsg: navigationMsg,
            error: error
        )
    }
}

extension Model {
    fileprivate func getProductListEffect(
        group: Group
    ) -> Effect<Msg>  {
        { dispatch in
            updateSortedProducts(group: group, dispatch: dispatch)
            apiManager.getProducts(group: group) { result in
                result.get(
                    errorDispatch: dispatch
                ) { _ in
                    updateSortedProducts(group: group, dispatch: dispatch)
                }
            }
        }
    }
    
    fileprivate func updateSortedProducts(
        group: Group,
        dispatch: @escaping Dispatch<Msg>
    ) {
        let predicate = NSPredicate(
            format: "ownerId == \(-group.id)"
        )
        let sortDescriptors = [
            NSSortDescriptor(
                key: #keyPath(Product.id),
                ascending: false
            ),
        ]
        managedObjectContext.perform {
            let res: [Product] = managedObjectContext
                .get(
                    predicate: predicate,
                    sortDescriptors: sortDescriptors
                )
            dispatch(
                .updateProductList(res)
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
