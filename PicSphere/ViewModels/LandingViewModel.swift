//
//  LandingViewModel.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 19/07/24.
//

import Foundation

class LandingViewModel {
    
    func restoreSession(completion: @escaping (Result<Void, Error>) -> Void) {
        if SessionManager.shared.isLoggedIn {
            // If logged in, attempt to fetch user details
            fetchUserDetails { result in
                switch result {
                case .success:
                    completion(.success(())) // Session restored successfully
                case .failure(let error):
                    print("Failed to fetch user details during session restoration: \(error.localizedDescription)")
                    completion(.failure(error)) // Session restoration failed
                }
            }
        } else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error)) // Not logged in
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
    
    func register(request: RegisterRequest, completion: @escaping (Result<Void, Error>) -> Void) {
        AuthenticationHandler.register(request: request) { result in
            switch result {
            case .success:
                // Registering may implicitly log in the user, so fetch user details after registration
                SessionManager.shared.isLoggedIn = true
                self.fetchUserDetails { fetchResult in
                    completion(fetchResult)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
