//
//  HomeViewModel.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 24/07/24.
//

import Foundation

class HomeViewModel {
    
    private var posts: [PostModel] = []
    private var stories: [StoryModel] = []
    
    // Fetch data for posts and stories using completion handlers
    func fetchData(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = UserState.shared.profile?.userId else {
            completion(.failure(NSError(domain: "com.yourdomain.yourapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])))
            return
        }
        
        // Fetch user details to get followingUserId
        AuthenticationHandler.fetchUserDetails(userId: currentUserId) { [weak self] result in
            switch result {
            case .success(let profile):
                let followingUserId = profile.followingUserId
                print("Retrieved following user id: \(followingUserId)")
                
                // Fetch followed posts
                PostsHandler.fetchFollowedPosts(followingUserId: followingUserId) { [weak self] result in
                    var postsError: Error?
                    switch result {
                    case .success(let fetchedPosts):
                        self?.posts = fetchedPosts
                        print("Successfully fetched posts: \(fetchedPosts)")
                    case .failure(let error):
                        postsError = error
                        print("Error fetching posts: \(error)")
                    }
                    
                    // Proceed to fetch stories even if there is an error in fetching posts
                    self?.fetchStories(followingUserId: followingUserId, postsError: postsError, completion: completion)
                }
                
            case .failure(let error):
                completion(.failure(error))
                print("Error fetching user details: \(error)")
            }
        }
    }
    
    private func fetchStories(followingUserId: [String], postsError: Error?, completion: @escaping (Result<Void, Error>) -> Void) {
        print("Fetching stories for following user id: \(followingUserId)")
        
        // Fetch followed stories
        PostsHandler.fetchFollowedStories(followingUserId: followingUserId) { [weak self] result in
            var storiesError: Error?
            switch result {
            case .success(let fetchedStories):
                self?.stories = fetchedStories
                print("Successfully fetched stories: \(fetchedStories)")
            case .failure(let error):
                storiesError = error
                print("Error fetching stories: \(error)")
            }
            
            // Call completion handler with the first encountered error, if any
            if let error = postsError ?? storiesError {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // Fetch user ID for a post at the given index
    func selectedUserId(forPostAt index: Int) -> String? {
        guard index < posts.count else {
            print("Post index out of range")
            return nil
        }
        
        return posts[index].userId
    }
    
    // Number of posts
    func numberOfPosts() -> Int {
        return posts.count
    }
    
    // Post at specific index
    func post(at index: Int) -> PostModel {
        return posts[index]
    }
    
    // Number of stories
    func numberOfStories() -> Int {
        return stories.count
    }
    
    // Story at specific index
    func story(at index: Int) -> StoryModel {
        return stories[index]
    }
}
