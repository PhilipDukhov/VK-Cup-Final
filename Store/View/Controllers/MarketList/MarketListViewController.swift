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
    private var dispatch: Dispatch<MarketListLeaf.Msg>?
    private var collectionViewWrapper: CollectionViewWrapper!
    private let titleView = MarketListTitleView()
    private let segueHelper = R.segue.marketListViewController.self
    
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
        _ = segueHelper.selectCity(
            segue: segue
        )?.destination.apply {
            $0.initialInfo = sender as? ChooseCityLeaf.Model.InitialInfo
            $0.selectCity = .init { [weak self] city in
                self?.dispatch?(.updateCityFromPicker(city))
            }
        }
        ?? segueHelper.groupProducts(
            segue: segue
        )?.destination.apply {
            $0.initialInfo = sender as? ProductsListLeaf.Model.InitialInfo
        }
        ?? segueHelper.camera(
            segue: segue
        )?.destination.apply {
            $0.functionality = .qrReader
        }
    }
    
    private func render(
        props: MarketListLeaf.Props,
        dispatch: @escaping Dispatch<MarketListLeaf.Msg>
    ) {
        self.dispatch = dispatch
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
        props.navigationMsg.mapOnMain(handleNavigationMsg)
        props.error.map {
            presentError($0)
            dispatch(.setError(nil))
        }
    }
    
    private func handleNavigationMsg(
        navigationMsg: MarketListLeaf.NavigationMsg
    ) {
        switch navigationMsg {
        case .chooseCity(let initialInfo):
            performSegue(
                withIdentifier: segueHelper.selectCity,
                sender: initialInfo
            )
        case .selectGroup(let initialInfo):
            performSegue(
                withIdentifier: segueHelper.groupProducts,
                sender: initialInfo
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
