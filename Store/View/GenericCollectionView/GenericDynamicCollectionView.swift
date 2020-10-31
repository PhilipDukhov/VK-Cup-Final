//
//  GenericDynamicCollectionView.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import UIKit
import DeepDiff

class CollectionViewWrapper: NSObject {
    typealias Cell = UICollectionViewCell
    
    struct Section {
        var numberOfColumns: Int
        var estimatedHeight: CGFloat?
        var insets: UIEdgeInsets?
        var minimumLineSpacing: CGFloat?
        var minimumInteritemSpacing: CGFloat?
        
        var items: [CollectionDescriptiveModel]
        
        init(
            numberOfColumns: Int = 1,
            estimatedHeight: CGFloat? = nil,
            insets: UIEdgeInsets? = nil,
            minimumLineSpacing: CGFloat? = nil,
            minimumInteritemSpacing: CGFloat? = nil,
            items: [CollectionDescriptiveModel] = [])
        {
            self.numberOfColumns = numberOfColumns
            self.estimatedHeight = estimatedHeight
            self.insets = insets
            self.minimumLineSpacing = minimumLineSpacing
            self.minimumInteritemSpacing = minimumInteritemSpacing
            self.items = items
        }
    }
    
    var didSelect: (CollectionDescriptiveModel, IndexPath) -> Void = { _, _ in }
    private var _sections: [Section] = []
    var sections: [Section] {
        get { _sections }
        set {
            executeOnMainQueue { [self] in
                _sections = newValue
                collectionView.reloadData()
            }
        }
    }
    
    func update(
        sections: [Section]
    ) {
        let difference = sections
            .enumerated()
            .reduce(
                into: [IndexPathDifference]()
            ) { result, pair in
                let oldItems = self.sections[pair.offset].items
                    .map { $0.descriptor }
                pair.element.items
                    .map { $0.descriptor }
                    .indexPathDifference(
                        for: pair.offset,
                        from: oldItems
                    ).map {
                        result += $0
                    }
            }
        print(difference)
        guard !difference.isEmpty else { return }
        executeOnMainQueue { [self] in
            collectionView.performBatchUpdates {
                _sections = sections
                for change in difference {
                    switch change {
                    case let .move(at, to):
                        collectionView.moveItem(at: at, to: to)
                        
                    case let .delete(at):
                        collectionView.deleteItems(at: [at])
                        
                    case let .insert(at):
                        collectionView.insertItems(at: [at])
                        
                    case let .replace(at):
                        collectionView.reloadItems(at: [at])
                        
                    case let .reload(section):
                        collectionView.reloadSections(.init(integer: section))
                    }
                }
            }
        }
    }
    
    private let collectionView: UICollectionView
    
    init(
        collectionView: UICollectionView,
        sections: [Section]
    ) {
        self.collectionView = collectionView
        _sections = sections
        super.init()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
    }
}

extension CollectionViewWrapper: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        // swiftlint:disable:next force_cast
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let section = sections[indexPath.section]
        let width = (
            (collectionView.bounds.width - flowLayout.minimumInteritemSpacing * CGFloat(section.numberOfColumns - 1)
            ) / CGFloat(section.numberOfColumns)
                
        ).rounded(.down)
        return .init(
            width: width,
            height: item(for: indexPath).cellHeightForWidth(width)
        )
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        insetsForItemsInSection section: Int
    ) -> UIEdgeInsets {
        .zero//sections[section].insets ?? .init(top: 0, left: .defaultInset, bottom: 0, right: .defaultInset)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        minimumLineSpacingForItemsInSection section: Int
    ) -> CGFloat {
        0//sections[section].minimumLineSpacing ?? .defaultInset
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        minimumInteritemSpacingForItemsInSection section: Int
    ) -> CGFloat {
        0//sections[section].minimumInteritemSpacing ?? .defaultInset
    }
    
    private func item(
        for indexPath: IndexPath
    ) -> CollectionDescriptiveModel {
        sections[indexPath.section].items[indexPath.item]
    }
    
    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        sections.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        sections[section].items.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(
            withReuseIdentifier: item(for: indexPath).descriptor.reuseIdentifier,
            for: indexPath
        )
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        item(for: indexPath).descriptor.configure(cell)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        didSelect(item(for: indexPath), indexPath)
    }
}

extension CGFloat {
    static let defaultInset: CGFloat = 0
}

extension UICollectionView {
    func registerDescribing<Cell: UICollectionViewCell>(_ cellClass: Cell.Type) {
        register(cellClass, forCellWithReuseIdentifier: .init(describing: Cell.self))
    }
    
    func dequeueDescribingReusableCell<Cell: UICollectionViewCell>(for indexPath: IndexPath) -> Cell {
        // swiftlint:disable:next force_cast
        dequeueReusableCell(withReuseIdentifier: .init(describing: Cell.self), for: indexPath) as! Cell
    }
}
