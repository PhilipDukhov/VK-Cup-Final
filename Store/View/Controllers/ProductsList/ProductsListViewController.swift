//
//  ProductsListViewController.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import UIKit

class ProductsListViewController: UIViewController {
    var initialInfo: ProductsListLeaf.Model.InitialInfo!
    
    @IBOutlet private var collectionView: UICollectionView!
    
    private var runtime: Any?
    private var collectionViewWrapper: CollectionViewWrapper!
    private let segueHelper = R.segue.productsListViewController.self
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Товары общества \(initialInfo.group.name)"
        collectionViewWrapper = CollectionViewWrapper(
            collectionView: collectionView,
            sections: [.productsListSection()]
        )
        runtime = ProductsListLeaf.runtime(
            initialInfo: initialInfo
        ) { [weak self] in
            self?.render(props: $0, dispatch: $1)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segueHelper.selectProduct(
            segue: segue
        )?.destination.apply {
            $0.initialInfo = sender as? ProductPageLeaf.Model.InitialInfo
        }
    }
    
    private func render(
        props: ProductsListLeaf.Props,
        dispatch: @escaping Dispatch<ProductsListLeaf.Msg>
    ) {
        collectionViewWrapper.sections = [
            .productsListSection(
                rows: props.products.map { product in
                    ProductListCellModel(
                        props: .init(
                            photoSizes: product.photos.first?.sizes,
                            title: product.title,
                            subtitle: product.price.text
                        )
                    )
                }
            )
        ]
        collectionViewWrapper.didSelect = { _, indexPath in
            dispatch(.selectProduct(props.products[indexPath.item]))
        }
        props.navigationMsg.mapOnMain(handleNavigationMsg)
        props.error.map { print($0) }
    }
    
    private func handleNavigationMsg(
        navigationMsg: ProductsListLeaf.NavigationMsg
    ) {
        switch navigationMsg {
        case .selectProduct(let initialInfo):
            performSegue(
                withIdentifier: segueHelper.selectProduct,
                sender: initialInfo
            )
        }
    }
}

extension CollectionViewWrapper.Section {
    fileprivate static func productsListSection(
        rows: [CollectionDescriptiveModel] = []
    ) -> Self {
        .init(
            numberOfColumns: 2,
            items: rows
        )
    }
}
