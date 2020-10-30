//
//  UINavigationController+replaceTopController.swift
//  Store
//
//  Created by Philip Dukhov on 10/31/20.
//

import UIKit

extension UINavigationController {
    func replaceTopController(
        with controller: UIViewController,
        animated: Bool = false
    ) {
        var viewControllers = self.viewControllers
        viewControllers.removeLast()
        viewControllers.append(controller)
        setViewControllers(
            viewControllers,
            animated: animated
        )
    }
}
