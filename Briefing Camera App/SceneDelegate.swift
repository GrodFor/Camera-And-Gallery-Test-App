//
//  SceneDelegate.swift
//  Briefing Camera App
//
//  Created by Vladislav Sitsko on 16.10.23.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        let viewController = MainViewController()
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()        
    }

}

