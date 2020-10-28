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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.authorize()
        }
    }
    
    func authorize() {
        authManager.authorize { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.performSegue(
                        withIdentifier: R.segue.authViewController.showNext,
                        sender: nil
                    )
                    
                case .failure:
                    self?.authorize()
                }
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
