//
//  ViewProfileViewModel.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 26/07/24.
//

import Foundation

class ViewProfileViewModel {
    
    private var profileDetails: ProfileModel?
    private var userPosts: [PostModel] = []
    
    // Fetch profile details for a user
    func fetchProfileDetails(userId: String, completion: @escaping (Result<ProfileModel, Error>) -> Void) {
        AuthenticationHandler.fetchUserDetails(userId: userId) { result in
            switch result {
            case .success(let profile):
                self.profileDetails = profile
                completion(.success(profile))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Fetch posts for the profile
    func fetchProfilePosts(userId: String, completion: @escaping (Result<[PostModel], Error>) -> Void) {
        PostsHandler.fetchProfilePosts(userId: userId) { result in
            switch result {
            case .success(let posts):
                self.userPosts = posts
                completion(.success(posts))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Follow a user
    func followUser(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        AuthenticationHandler.followUser(followingUserId: userId) { result in
            switch result {
            case .success:
                self.updateProfileDetailsOnFollow(userId: userId, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Unfollow a user
    func unfollowUser(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        AuthenticationHandler.unfollowUser(followingUserId: userId) { result in
            switch result {
            case .success:
                self.updateProfileDetailsOnUnfollow(userId: userId, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Update profile details after following a user
    private func updateProfileDetailsOnFollow(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        fetchProfileDetails(userId: userId) { result in
            switch result {
            case .success(let profile):
                self.profileDetails = profile
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Update profile details after unfollowing a user
    private func updateProfileDetailsOnUnfollow(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        fetchProfileDetails(userId: userId) { result in
            switch result {
            case .success(let profile):
                self.profileDetails = profile
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Get profile details
    func getProfileDetails() -> ProfileModel? {
        return profileDetails
    }
    
    // Get user posts
    func getUserPosts() -> [PostModel] {
        return userPosts
    }
    
    // Number of posts
    func numberOfPosts() -> Int {
        return userPosts.count
    }
    
    // Post at specific index
    func post(at index: Int) -> PostModel {
        return userPosts[index]
    }
    
    // Check if current user is following the profile user
    func isFollowing(profileUserId: String, completion: @escaping (Bool) -> Void) {
        AuthenticationHandler.isFollowing(userIdToCheck: profileUserId) { result in
            switch result {
            case .success(let isFollowing):
                completion(isFollowing)
            case .failure:
                completion(false)
            }
        }
    }
}
