//
//  LoginViewModel.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 19/07/24.
//

import Foundation

class LoginViewModel {
    
    func login(request: LoginRequest, completion: @escaping (Result<Void, Error>) -> Void) {
        AuthenticationHandler.login(request: request) { result in
            switch result {
            case .success:
                // Fetch user details after successful login
                self.fetchUserDetails(completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchUserDetails(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = UserState.shared.currentUserId else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "Current user ID not found"])
            completion(.failure(error))
            return
        }
        
        AuthenticationHandler.fetchUserDetails(userId: currentUserId) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

