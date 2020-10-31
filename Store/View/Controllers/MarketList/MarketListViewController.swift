//
//  MarketListViewController.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import UIKit
import Rswift

class MarketListViewController: UIViewController {
    @IBOutlet private var collectionView: UICollectionView!
    
    private var runtime: Any?
    private var collectionViewWrapper: CollectionViewWrapper!
    private let titleView = MarketListTitleView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionViewWrapper = CollectionViewWrapper(
            collectionView: collectionView,
            sections: [.marketListSection()]
        )
        titleView.frame = .init(origin: .zero, size: .init(width: 300, height: 100))
        navigationItem.titleView = titleView
        runtime = MarketListLeaf.runtime { [weak self] in
            self?.render(props: $0, dispatch: $1)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        R.segue.marketListViewController.camera(
            segue: segue
        )?.destination.apply {
            $0.functionality = .qrReader
        }
    }
    
    private func render(
        props: MarketListLeaf.Props,
        dispatch: @escaping Dispatch<MarketListLeaf.Msg>
    ) {
        titleView.props = props.city.map { city in
            .init(
                title: city.marketsListDescription,
                action: .init {
                    dispatch(.chooseCity)
                }
            )
        }
        collectionViewWrapper.update(sections: [
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
        ])
        collectionViewWrapper.didSelect = { _, indexPath in
            dispatch(.selectGroup(props.groups[indexPath.item]))
        }
        props.navigationMsg.mapOnMain { [self] in
            handleNavigationMsg($0, dispatch: dispatch)
            dispatch(.clearNavigationMsg)
        }
        props.error.map {
            present(error: $0)
            dispatch(.setError(nil))
        }
    }
    
    private func handleNavigationMsg(
        _ navigationMsg: MarketListLeaf.NavigationMsg,
        dispatch: @escaping Dispatch<MarketListLeaf.Msg>
    ) {
        switch navigationMsg {
        case .chooseCity(let initialInfo):
            present(
                R.storyboard.main
                    .chooseCityViewController()!
                    .apply {
                        $0.initialInfo = initialInfo
                        $0.selectCity = .init {
                            dispatch(.updateCityFromPicker($0))
                        }
                    },
                animated: true
            )
        case .selectGroup(let initialInfo):
            navigationController?.pushViewController(
                R.storyboard.main
                    .productsListViewController()!
                    .apply {
                        $0.initialInfo = initialInfo
                    },
                animated: true
            )
        }
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

extension City {
    fileprivate var marketsListDescription: String {
        if let inflectedTitle = inflectedTitle {
            return "Магазины в \(inflectedTitle)"
        } else {
            return "Магазины в городе \(title)"
        }
    }
}

extension CollectionViewWrapper.Section {
    fileprivate static func marketListSection(
        rows: [CollectionDescriptiveModel] = []
    ) -> Self {
        .init(
            items: rows
        )
    }
}
