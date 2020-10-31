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
//                    self?.testVideoUpload()
//                    self?.openRecorder()
                    self?.navigationController?.replaceTopController(
                        with: R.storyboard.main.marketListViewController()!
                    )
                    
                case .failure:
                    self?.authorize()
                }
            }
        }
    }
    
    private let shareStoryApiManager = ShareStoryApiManager()
    
//    private func testVideoUpload() {
//        let file = R.file.testMp4()!
//        getProduct { [weak self] product in
//            self?.shareStoryApiManager
//                .uploadVideo(
//                    videoURL: file,
//                    product: product
//                ) { progress in
//                    executeOnMainQueue { [weak self] in
////                        self?.state = .exporting(0.5 + 0.5 * progress)
//                    }
//                } completion: { result in
//                    executeOnMainQueue { [weak self] in
////                        self?.state = .idle
//                        print(result)
//                        // self?.dismissAfterFinished()
//                    }
//                }
//        }
//    }
    
//    private func testUpload() {
//        let photo = UIImage(named: "profile")!
//        let screenSize = UIScreen.main.bounds.size
//        let photoSize = photo.size
//        
//        var scale: CGFloat = screenSize.width / photoSize.width
//        if photoSize.height * scale < screenSize.height {
//            scale = screenSize.height / photoSize.height
//        }
//        
//        let croppedPhotoSize = CGSize(
//            width: screenSize.width / scale,
//            height: screenSize.height / scale
//        )
//        let cropRect = CGRect(
//            origin: CGPoint(
//                x: (croppedPhotoSize.width - photoSize.width) / 2,
//                y: (croppedPhotoSize.height - photoSize.height) / 2
//            ), size: croppedPhotoSize
//        )
//        let image = UIGraphicsImageRenderer(
//            size: cropRect.size
//        ).image { _ in
//            photo.draw(at: cropRect.origin)
//        }
//        
//        let url = URL(fileURLWithPath: NSTemporaryDirectory())
//            .appendingPathComponent("file.jpg")
//        try? FileManager.default.removeItem(at: url)
//        
//        var data: Data
//        var compressionQuality: CGFloat = 0
//        repeat {
//            data = image.jpegData(
//                compressionQuality: 0.1
//            )!
//            compressionQuality += 0.1
//        } while data.count < 1024 * 1024 && compressionQuality <= 1
//        try? data.write(to: url)
//        shareStoryApiManager
//            .uploadPhoto(
//                photoURL: url
//            ) { result in
//                print(result)
//            }
//    }
    
    private let linkResolverApiManager = LinkResolverApiManager()
    
    private func getProduct(completion: @escaping (Product) -> Void) {
        linkResolverApiManager.getProduct(
            productId: "-184513691_4707020"
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
