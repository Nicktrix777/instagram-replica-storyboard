//
//  NavigationHelper.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 22/07/24.
//

import Foundation
import UIKit

class NavigationHelper {
    //MARK: -Change storyboard based on Auth Status
    
    static func changeRootViewController(vc:UIViewController) {
        DispatchQueue.main.async {
            // Instantiate your tab bar controller from the "Authenticated" storyboard
            if #available(iOS 13.0, *) {
                // Get the current window scene
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    // Get the key window associated with the scene
                    if let window = windowScene.windows.first {
                        window.rootViewController = vc
                        window.makeKeyAndVisible()
                    }
                }
            } else {
                // Fallback on earlier versions
                UIApplication.shared.keyWindow?.rootViewController = vc
                UIApplication.shared.keyWindow?.makeKeyAndVisible()
            }
        }
    }
    
    static func presentVcModally(vc: UIViewController, style: UIModalPresentationStyle? = .automatic) {
        if let topViewController = UIApplication.topViewController() {
            vc.modalPresentationStyle = style!
            topViewController.present(vc, animated: true, completion: nil)
        }
    }
}



extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
