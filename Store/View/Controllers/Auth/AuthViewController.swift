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
