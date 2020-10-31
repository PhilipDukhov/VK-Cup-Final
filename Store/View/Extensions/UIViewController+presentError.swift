//
//  UIViewController+presentError.swift
//  Store
//
//  Created by Philip Dukhov on 11/1/20.
//

import UIKit

extension UIViewController {
    @discardableResult
    func presentError(
        _ error: Error?,
        title: String? = nil
    ) -> UIAlertController {
        let block = { [self] () -> UIAlertController in
            let alert = UIAlertController(
                title: title ?? "Failed",
                message: error?.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(
                .init(
                    title: "OK",
                    style: .default,
                    handler: nil
                )
            )
            present(alert, animated: true)
            return alert
        }
        if Thread.isMainThread {
            return block()
        } else {
            return DispatchQueue.main.sync(execute: block)
        }
    }
}
