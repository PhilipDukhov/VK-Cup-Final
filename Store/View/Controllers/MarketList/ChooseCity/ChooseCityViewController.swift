//
//  ChooseCityViewController.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import UIKit

class ChooseCityViewController: UIViewController {
    var initialInfo: ChooseCityLeaf.Model.InitialInfo!
    var selectCity: ActionWith<City>!
    
    @IBOutlet private var collectionView: UICollectionView!
    
    private var runtime: Any?
    private var collectionViewWrapper: CollectionViewWrapper!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionViewWrapper = CollectionViewWrapper(
            collectionView: collectionView,
            sections: [.chooseCityListSection()]
        )
        runtime = ChooseCityLeaf.runtime(
            initialInfo: initialInfo
        ) { [weak self] in
            self?.render(props: $0, dispatch: $1)
        }
    }
    
    private func render(
        props: ChooseCityLeaf.Props,
        dispatch: Dispatch<ChooseCityLeaf.Msg>
    ) {
        collectionViewWrapper.update(sections: [
            .chooseCityListSection(
                rows: props.cities.map { city in
                    ChooseCityCellCellModel(
                        props: .init(
                            title: city.title,
                            selected: props.selectedCity == city
                        )
                    )
                }
            )
        ])
        collectionViewWrapper.didSelect = { [weak self] _, indexPath in
            self.map {
                $0.selectCity.execute(props.cities[indexPath.item])
                $0.dismiss(animated: true)
            }
        }
    }
}

extension CollectionViewWrapper.Section {
    fileprivate static func chooseCityListSection(
        rows: [CollectionDescriptiveModel] = []
    ) -> Self {
        .init(
            estimatedHeight: 48,
            items: rows
        )
    }
}
