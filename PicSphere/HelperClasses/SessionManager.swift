//
//  SessionManager.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 22/07/24.
//

import Foundation

class SessionManager {
    static let shared = SessionManager()

    private let userDefaults = UserDefaults.standard
    private let isLoggedInKey = "isLoggedIn"

    var isLoggedIn: Bool {
        get {
            return userDefaults.bool(forKey: isLoggedInKey)
        }
        set {
            userDefaults.set(newValue, forKey: isLoggedInKey)
        }
    }

    private init() {}
}
