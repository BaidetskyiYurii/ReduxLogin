//
//  ApplicationUtility.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 20.07.2024.
//

import UIKit

final class ApplicationUtility {
    static var rootViewController: UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return UIViewController()
        }
        
        guard let root = screen.windows.first?.rootViewController else {
            return UIViewController()
        }
        
        return root
    }

    static var topViewController: UIViewController? {
        var topController: UIViewController? = rootViewController
        
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
}
