//
//  RegisterRequest.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 19/07/24.
//

import Foundation

struct RegisterRequest: Codable {
    
    var username: String
    var email: String
    var password: String
    var confirmPassword: String
    
    func passwordsMatch() -> Bool {
        return password == confirmPassword
    }
}
