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
        VK.setUp(appId: "7642693", delegate: self)
        VK.sessions.default.config.language = .ru
        authorize()
    }
    
    func authorize() {
        authManager.authorize { [weak self] result in
            executeOnMainQueue {
                switch result {
                case .success:
                    self?.openRecorder()
//                    self?.navigationController?.replaceTopController(
//                        with: R.storyboard.main.marketListViewController()!
//                    )
                    
                case .failure:
                    self?.authorize()
                }
            }
        }
    }
    
    private let shareStoryApiManager = ShareStoryApiManager()
    
    private let linkResolverApiManager = LinkResolverApiManager()
    
    private func getProduct(completion: @escaping (Product) -> Void) {
        linkResolverApiManager.getProduct(
            productId: "-30232475_4118841"
        ) {
            (try? $0.get()).map(completion)
        }
    }
    
    private func openRecorder() {
        getProduct { [weak self] product in
            executeOnMainQueue {
                self?.navigationController?.replaceTopController(
                    with: R.storyboard.main.cameraViewController()!.apply {
                        $0.functionality = .recorder(product)
                    }
                )
            }
        }
    }
}

extension AuthViewController: SwiftyVKDelegate {
    func vkNeedsScopes(for sessionId: String) -> Scopes {
        [.market,
         .groups,
         .stories,
        ]
    }
    
    func vkNeedToPresent(viewController: VKViewController) {
        present(viewController, animated: true)
    }
}
