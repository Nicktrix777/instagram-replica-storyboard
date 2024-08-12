//
//  ProfileViewModel.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 22/07/24.
//

import Foundation

class ProfileViewModel {

    // Function to handle profile image upload or replacement
    func uploadOrReplaceProfileImage(imagePath: String, completion: @escaping (Result<String, Error>) -> Void) {
        let imageURL = URL(fileURLWithPath: imagePath)
        
        PostStorageHandler.uploadProfilePicture(imageURL: imageURL) { result in
            switch result {
            case .success(let newProfilePictureURL):
                AuthenticationHandler.updateProfilePicture(profilePictureURL: newProfilePictureURL) { result in
                    switch result {
                    case .success:
                        completion(.success(newProfilePictureURL))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func uploadStoryImage(imagePath: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let imageURL = URL(fileURLWithPath: imagePath)
        PostStorageHandler.uploadStory(imageURL: imageURL) { result in
            completion(result)
        }
    }

    func uploadPostImage(imagePath: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let imageURL = URL(fileURLWithPath: imagePath)
        PostStorageHandler.uploadPost(imageURL: imageURL) { result in
            completion(result)
        }
    }

    func editUsername(username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        AuthenticationHandler.updateUsername(newUsername: username, completion: completion)
    }

    func editPassword(password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        AuthenticationHandler.updatePassword(newPassword: password, completion: completion)
    }

    func editBio(bio: String, completion: @escaping (Result<Void, Error>) -> Void) {
        AuthenticationHandler.updateBio(newBio: bio, completion: completion)
    }

    // Function to handle user logout
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        AuthenticationHandler.logout { result in
            switch result {
            case .success:
                // Additional cleanup or UI updates if needed
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
