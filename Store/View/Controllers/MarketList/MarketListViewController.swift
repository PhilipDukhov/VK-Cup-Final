//
//  MarketListViewController.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import UIKit

class MarketListViewController: UIViewController {
    private var runtime: Any?
    
    @IBOutlet private var collectionView: UICollectionView!
//    @IBOutlet var navigationTitleView: UIView!
    
    private var collectionViewWrapper: CollectionViewWrapper!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionViewWrapper = CollectionViewWrapper(
            collectionView: collectionView,
            sections: [.marketListSection()]
        )
        runtime = Runtime(
            initial: MarketListLeaf.initial,
            update: MarketListLeaf.update,
            view: MarketListLeaf.view
        ) { [weak self] in
            self?.render(props: $0, dispatch: $1)
        }
        view.backgroundColor = .gray
    }
    
    private func render(
        props: MarketListLeaf.Props,
        dispatch: Dispatch<MarketListLeaf.Msg>
    ) {
        collectionViewWrapper.sections = [
            .marketListSection(
                rows: props.groups.map { group in
                    MarketListCellModel(
                        props: .init(
                            photoSizes: group.photoSizes,
                            title: group.name,
                            subtitle: group.visibility.description
                        )
                    )
                }
            )
        ]
    }
}

extension Group.Visibility {
    fileprivate var description: String {
        switch self {
        case .closed:
            return "Закрытая группа"
        case .opened:
            return "Открытая группа"
        }
    }
}

extension CollectionViewWrapper.Section {
    fileprivate static func marketListSection(
        rows: [CollectionDescriptiveModel] = []
    ) -> Self {
        .init(
            numberOfColumns: 1,
            estimatedHeight: 60,
            rows: rows
        )
    }
}
