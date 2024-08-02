//
//  UserState.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 24/07/24.
//

import Foundation

class UserState {
    static let shared = UserState()

    private let userDefaults = UserDefaults.standard
    private let profileKey = "profile"

    var profile: ProfileModel? {
        get {
            if let profileData = userDefaults.data(forKey: profileKey) {
                return try? JSONDecoder().decode(ProfileModel.self, from: profileData)
            }
            return nil
        }
        set {
            if let newValue = newValue, let encoded = try? JSONEncoder().encode(newValue) {
                userDefaults.set(encoded, forKey: profileKey)
            } else {
                userDefaults.removeObject(forKey: profileKey)
            }
        }
    }
    
    var currentUserId: String? {
        return profile?.userId
    }

    private init() {}
}
