//
//  PostsHandler.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 24/07/24.
//

import FirebaseDatabase
import Foundation

class PostsHandler {
    private static let ref = Database.database().reference()
    
    // Fetch posts for a single user
    static func fetchProfilePosts(userId: String, completion: @escaping (Result<[PostModel], Error>) -> Void) {
        ref.child("posts").queryOrdered(byChild: "userId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
            print("Fetched posts snapshot for userId: \(userId)")
            print("Snapshot value: \(snapshot.value ?? "nil")")
            
            var postData: [PostModel] = []
            
            for child in snapshot.children {
                guard let childSnapshot = child as? DataSnapshot,
                      let postDict = childSnapshot.value as? [String: Any] else {
                    print("Error parsing post snapshot for userId: \(userId). Child snapshot: \(child)")
                    continue
                }
                
                let post = PostModel(
                    postId: postDict["postId"] as? String ?? "",
                    userId: postDict["userId"] as? String ?? "",
                    username: postDict["username"] as? String ?? "",
                    profilePictureURL: postDict["profilePictureURL"] as? String ?? "",
                    postURL: postDict["postURL"] as? [String] ?? [],
                    commentCount: postDict["commentCount"] as? Int ?? 0,
                    likeCount: postDict["likeCount"] as? Int ?? 0
                )
                
                postData.append(post)
            }
            
            print("Post data for userId \(userId): \(postData)")
            completion(.success(postData))
        } withCancel: { error in
            print("Error fetching posts for userId: \(userId), \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    // Fetch stories for a single user
    static func fetchProfileStories(userId: String, completion: @escaping (Result<[StoryModel], Error>) -> Void) {
        ref.child("stories").queryOrdered(byChild: "userId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
            print("Fetched stories snapshot for userId: \(userId)")
            print("Snapshot value: \(snapshot.value ?? "nil")")
            
            var storyData: [StoryModel] = []
            
            for child in snapshot.children {
                guard let childSnapshot = child as? DataSnapshot,
                      let storyDict = childSnapshot.value as? [String: Any] else {
                    print("Error parsing story snapshot for userId: \(userId). Child snapshot: \(child)")
                    continue
                }
                
                let story = StoryModel(
                    storyPostId: storyDict["storyPostId"] as? String ?? "",
                    userId: storyDict["userId"] as? String ?? "",
                    profilePictureURL: storyDict["profilePictureURL"] as? String ?? "",
                    username: storyDict["username"] as? String ?? "",
                    storyPostURL: storyDict["storyPostURL"] as? [String] ?? []
                )
                
                storyData.append(story)
            }
            
            print("Story data for userId \(userId): \(storyData)")
            completion(.success(storyData))
        } withCancel: { error in
            print("Error fetching stories for userId: \(userId), \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    // Fetch followed posts with completion handler
    static func fetchFollowedPosts(followingUserId: [String], completion: @escaping (Result<[PostModel], Error>) -> Void) {
        var allPosts: [PostModel] = []
        var pendingUserIds = followingUserId
        var fetchError: Error?
        
        func fetchNext() {
            guard !pendingUserIds.isEmpty else {
                // No more userIds to process
                if let error = fetchError {
                    completion(.failure(error))
                } else {
                    print("Fetched all followed posts: \(allPosts)")
                    completion(.success(allPosts))
                }
                return
            }
            
            let userId = pendingUserIds.removeFirst()
            print("Fetching posts for userId: \(userId)")
            
            fetchProfilePosts(userId: userId) { result in
                switch result {
                case .success(let posts):
                    allPosts.append(contentsOf: posts)
                case .failure(let error):
                    fetchError = error
                }
                
                // Fetch the next userId
                fetchNext()
            }
        }
        
        // Start fetching
        fetchNext()
    }

    // Fetch followed stories with completion handler
    static func fetchFollowedStories(followingUserId: [String], completion: @escaping (Result<[StoryModel], Error>) -> Void) {
        var allStories: [StoryModel] = []
        var pendingUserIds = followingUserId
        var fetchError: Error?
        
        func fetchNext() {
            guard !pendingUserIds.isEmpty else {
                // No more userIds to process
                if let error = fetchError {
                    completion(.failure(error))
                } else {
                    print("Fetched all followed stories: \(allStories)")
                    completion(.success(allStories))
                }
                return
            }
            
            let userId = pendingUserIds.removeFirst()
            print("Fetching stories for userId: \(userId)")
            
            fetchProfileStories(userId: userId) { result in
                switch result {
                case .success(let stories):
                    allStories.append(contentsOf: stories)
                case .failure(let error):
                    fetchError = error
                }
                
                // Fetch the next userId
                fetchNext()
            }
        }
        
        // Start fetching
        fetchNext()
    }
    
    // Fetch comments for a specific post
    static func fetchComments(for postId: String, completion: @escaping (Result<[CommentModel], Error>) -> Void) {
        ref.child("comments").queryOrdered(byChild: "postId").queryEqual(toValue: postId).observeSingleEvent(of: .value) { snapshot in
            print("Fetched comments snapshot for postId: \(postId)")
            print("Snapshot value: \(snapshot.value ?? "nil")")
            
            var comments: [CommentModel] = []
            
            for child in snapshot.children {
                guard let snapshot = child as? DataSnapshot,
                      let commentDict = snapshot.value as? [String: Any] else {
                    print("Error parsing comment snapshot for postId: \(postId). Child snapshot: \(child)")
                    continue
                }
                
                if let comment = CommentModel(dictionary: commentDict) {
                    comments.append(comment)
                } else {
                    print("Failed to initialize CommentModel from dictionary: \(commentDict)")
                }
            }
            
            print("Comments data for postId \(postId): \(comments)")
            completion(.success(comments))
        } withCancel: { error in
            print("Error fetching comments for postId: \(postId), \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    // Add a like to a post
    static func addLike(toPostId postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let postRef = ref.child("posts").child(postId)
        
        postRef.observeSingleEvent(of: .value) { snapshot in
            print("Fetched post snapshot for adding like to postId: \(postId)")
            print("Snapshot value: \(snapshot.value ?? "nil")")
            
            guard var postDict = snapshot.value as? [String: Any],
                  let currentLikes = postDict["likeCount"] as? Int else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch post data"])))
                return
            }
            
            // Update like count
            let newLikeCount = currentLikes + 1
            postDict["likeCount"] = newLikeCount
            
            postRef.updateChildValues(postDict) { error, _ in
                if let error = error {
                    print("Error updating post with new like count: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Successfully added like to postId: \(postId)")
                    completion(.success(()))
                }
            }
        }
    }
        
    // Remove a like from a post
    static func removeLike(fromPostId postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let postRef = ref.child("posts").child(postId)
        
        postRef.observeSingleEvent(of: .value) { snapshot in
            print("Fetched post snapshot for removing like from postId: \(postId)")
            print("Snapshot value: \(snapshot.value ?? "nil")")
            
            guard var postDict = snapshot.value as? [String: Any],
                  let currentLikes = postDict["likeCount"] as? Int else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch post data"])))
                return
            }
            
            // Update like count
            let newLikeCount = max(currentLikes - 1, 0)
            postDict["likeCount"] = newLikeCount
            
            postRef.updateChildValues(postDict) { error, _ in
                if let error = error {
                    print("Error updating post with new like count: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Successfully removed like from postId: \(postId)")
                    completion(.success(()))
                }
            }
        }
    }
}
