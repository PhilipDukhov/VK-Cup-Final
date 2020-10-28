//
//  CollectionDescriptiveModel.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import UIKit
import DeepDiff

protocol CollectionDescriptiveModel {
    var descriptor: CollectionCellDescriptor { get }
    var cellHeightForWidth: (CGFloat) -> (CGFloat) { get }
}
