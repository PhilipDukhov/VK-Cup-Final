//
//  AuthViewController.swift
//  Store
//
//  Created by Philip Dukhov on 10/27/20.
//

import UIKit
import SwiftyVK

class AuthViewController: UIViewController {
    private let authManager = VkAuthManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        VK.setUp(appId: "7339682", delegate: self)
        VK.sessions.default.config.language = .ru
        authorize()
    }
    
    func authorize() {
        authManager.authorize { [weak self] result in
            executeOnMainQueue {
                switch result {
                case .success:
                    self?.navigationController?.replaceTopController(
                        with: R.storyboard.main.marketListViewController()!
                    )
                    
                case .failure:
                    self?.authorize()
                }
            }
        }
    }
    
    let baseApiManager = BaseApiManager()
    
    private func showPage(url: URL) { 
//        self?.showPage(url: URL(string: "https://vk.com/market-41348582?w=product-41348582_253062")!)
        let wPrefix = "product"
        guard
            let urlComponents = URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            ),
            let queryItems = urlComponents.queryItems,
            let w = queryItems
                .first(where: { $0.name == "w" })?
                .value,
            w.hasPrefix(wPrefix)
        else { return }
        let productId = String(
            w.suffix(
                from: w.index(
                    w.startIndex,
                    offsetBy: wPrefix.count
                )
            )
        )
        baseApiManager.sendHandleAndParseFirst(
            VK.API.Market.getById([
                .itemIds: productId,
                .extended: 1,
            ].stringify),
            container: .items) { [weak self] (result: Result<Product, BaseApiManager.Error>) in
            switch result {
            case .success(let product):
                executeOnMainQueue {
                    let pageVC = R.storyboard.main.productPageViewController()!
                    pageVC.initialInfo = .init(product: product)
                    self?.navigationController?.viewControllers = [
                        pageVC
                    ]
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}

extension AuthViewController: SwiftyVKDelegate {
    func vkNeedsScopes(for sessionId: String) -> Scopes {
        [.market,
         .groups,
        ]
    }
    
    func vkNeedToPresent(viewController: VKViewController) {
        present(viewController, animated: true)
    }
}
