//
//  ProductPageViewController.swift
//  Store
//
//  Created by Philip Dukhov on 10/30/20.
//

import UIKit

class ProductPageViewController: UIViewController {
    var initialInfo: ProductPageLeaf.Model.InitialInfo!
    
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var priceLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var favoriteButton: SelectableButton!
        
    private var runtime: Any?
    private var collectionViewWrapper: CollectionViewWrapper!
    private let segueHelper = R.segue.marketListViewController.self
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = initialInfo.product.title
        title = initialInfo.product.title
        priceLabel.text = initialInfo.product.price.text
        descriptionLabel.text = initialInfo.product.description
        collectionViewWrapper = CollectionViewWrapper(
            collectionView: collectionView,
            sections: [.productPageSection(
                rows: initialInfo.product.photos.map {
                    ProductImageCellModel(
                        props: .init(photoSizes: $0.sizes)
                    )
                }
            )]
        )
        runtime = ProductPageLeaf.runtime(
            initialInfo: initialInfo
        ) { [weak self] in
            self?.render(props: $0, dispatch: $1)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        R.segue.productPageViewController.story(
            segue: segue
        )?.destination.apply {
            $0.functionality = .recorder(initialInfo.product)
        }
    }
    
    private func render(
        props: ProductPageLeaf.Props,
        dispatch: @escaping Dispatch<ProductPageLeaf.Msg>
    ) {
        executeOnMainQueue { [self] in
            favoriteButton.customSelected = props.isFavorite
        }
        favoriteButton.action = .init {
            dispatch(.setFavorite(!props.isFavorite))
        }
        props.error.map {
            present(error: $0)
            dispatch(.setError(nil))
        }
    }
}

extension CollectionViewWrapper.Section {
    fileprivate static func productPageSection(
        rows: [CollectionDescriptiveModel] = []
    ) -> Self {
        .init(
            items: rows
        )
    }
}
