//
//  AppDelegate.swift
//  Store
//
//  Created by Philip Dukhov on 10/27/20.
//

import UIKit
import SwiftyVK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        (window?.rootViewController as? UINavigationController).map {
            _ = $0.navigationBar.apply {
                $0.shadowImage = .init()
                $0.backgroundColor = .white
                $0.isTranslucent = false
                $0.tintColor = .vkBlue
                $0.titleTextAttributes = [
                    .font: UIFont.navigationBarTitleFont
                ]
            }
        }
        return true
    }
}
