//
//  PostStorageHandler.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 26/07/24.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase

class PostStorageHandler {

    private static let storage = Storage.storage()
    private static let db = Database.database().reference()

    // Upload a new post
    static func uploadPost(imageURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        print("Entered uploadPost")

        let postId = UUID().uuidString
        let userId = UserState.shared.currentUserId ?? ""

        guard let image = UIImage(contentsOfFile: imageURL.path) else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to load image from URL"])
            completion(.failure(error))
            return
        }

        guard let imageData = image.pngData() else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG data"])
            completion(.failure(error))
            return
        }

        let storageRef = storage.reference().child("posts/\(postId).png")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            print("Image uploaded successfully")

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Download URL error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let downloadURL = url else {
                    let error = NSError(domain: "com.yourdomain.yourapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                    print("Download URL error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                print("Download URL retrieved: \(downloadURL.absoluteString)")

                let postDetails = PostModel(
                    postId: postId,
                    userId: userId,
                    username: UserState.shared.profile?.username ?? "",
                    profilePictureURL: UserState.shared.profile?.profilePictureURL ?? "",
                    postURL: [downloadURL.absoluteString],
                    commentCount: 0,
                    likeCount: 0
                )

                let postRef = db.child("posts").child(postId)
                postRef.setValue(postDetails.toDictionary()) { error, ref in
                    if let error = error {
                        print("Database write error: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }

                    print("Post uploaded and saved successfully")

                    // Update the user's post count
                    incrementPostCount(for: userId) { result in
                        switch result {
                        case .success():
                            print("Post count updated successfully")
                            completion(.success(()))
                        case .failure(let error):
                            print("Failed to update post count: \(error.localizedDescription)")
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }

    // Upload a new story
    static func uploadStory(imageURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let userId = UserState.shared.currentUserId ?? ""

        guard let image = UIImage(contentsOfFile: imageURL.path) else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to load image from URL"])
            completion(.failure(error))
            return
        }

        guard let imageData = image.pngData() else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG data"])
            completion(.failure(error))
            return
        }

        let storageRef = storage.reference().child("stories/\(UUID().uuidString).png")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let downloadURL = url else {
                    let error = NSError(domain: "com.yourdomain.yourapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                    completion(.failure(error))
                    return
                }

                let storiesRef = db.child("stories")
                let query = storiesRef.queryOrdered(byChild: "userId").queryEqual(toValue: userId)

                query.observeSingleEvent(of: .value) { snapshot in
                    if snapshot.hasChildren() {
                        // Story exists for the current user
                        guard let storyDict = snapshot.children.allObjects.first as? DataSnapshot,
                              var storyData = storyDict.value as? [String: Any],
                              var storyPostURLArray = storyData["storyPostURL"] as? [String] else {
                            let error = NSError(domain: "com.yourdomain.yourapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "Story data not found"])
                            completion(.failure(error))
                            return
                        }

                        // Append the new URL to the existing story URLs
                        storyPostURLArray.append(downloadURL.absoluteString)
                        storyData["storyPostURL"] = storyPostURLArray

                        // Update the story in the database
                        storiesRef.child(storyDict.key).updateChildValues(storyData) { error, _ in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                completion(.success(()))
                            }
                        }
                    } else {
                        // No existing story, create a new one
                        let storyPostId = UUID().uuidString
                        let storyDetails = StoryModel(
                            storyPostId: storyPostId,
                            userId: userId,
                            profilePictureURL: UserState.shared.profile?.profilePictureURL ?? "",
                            username: UserState.shared.profile?.username ?? "",
                            storyPostURL: [downloadURL.absoluteString]
                        )

                        let newStoryRef = storiesRef.child(storyPostId)
                        newStoryRef.setValue(storyDetails.toDictionary()) { error, _ in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                completion(.success(()))
                            }
                        }
                    }
                }
            }
        }
    }

    // Upload a profile picture
    static func uploadProfilePicture(imageURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let image = UIImage(contentsOfFile: imageURL.path) else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to load image from URL"])
            completion(.failure(error))
            return
        }

        guard let imageData = image.pngData() else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG data"])
            completion(.failure(error))
            return
        }

        let storageRef = storage.reference().child("profile_picture/\(UUID().uuidString).png")

        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let downloadURL = url else {
                    let error = NSError(domain: "com.yourdomain.yourapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                    completion(.failure(error))
                    return
                }

                completion(.success(downloadURL.absoluteString))
            }
        }
    }

    // Replace a profile picture
    static func replaceProfilePicture(newImageURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = UserState.shared.currentUserId else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
            completion(.failure(error))
            return
        }

        db.child("users").child(currentUserId).observeSingleEvent(of: .value) { snapshot in
            guard let userDict = snapshot.value as? [String: Any],
                  let currentProfilePictureURL = userDict["profilePictureURL"] as? String else {
                let error = NSError(domain: "com.yourdomain.yourapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "Current profile picture URL not found"])
                completion(.failure(error))
                return
            }

            uploadProfilePicture(imageURL: newImageURL) { result in
                switch result {
                case .success(let newProfilePictureURL):
                    let oldProfilePictureRef = storage.reference(forURL: currentProfilePictureURL)
                    oldProfilePictureRef.delete { error in
                        if let error = error {
                            print("Failed to delete old profile picture: \(error.localizedDescription)")
                        }

                        db.child("users").child(currentUserId).updateChildValues(["profilePictureURL": newProfilePictureURL]) { error, _ in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                if var profile = UserState.shared.profile {
                                    profile.profilePictureURL = newProfilePictureURL
                                    UserState.shared.profile = profile
                                }
                                completion(.success(()))
                            }
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    // Upload a comment
    static func uploadComment(postId: String, commentText: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Retrieve the current user's profile from UserState
        guard let currentUserProfile = UserState.shared.profile else {
            // Handle the case where the user profile is not available
            let error = NSError(domain: "UserProfileError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Current user profile is not available."])
            completion(.failure(error))
            return
        }
        
        let commentId = UUID().uuidString // Generate a unique comment ID
        let comment = CommentModel(
            commentId: commentId,
            postId: postId,
            userId: currentUserProfile.userId,
            username: currentUserProfile.username,
            profilePictureURL: currentUserProfile.profilePictureURL ?? "",
            commentText: commentText
        )
        
        let commentRef = db.child("comments").child(comment.commentId)
        let postRef = db.child("posts").child(comment.postId)
        
        let commentData = comment.toDictionary()
        
        commentRef.setValue(commentData) { error, _ in
            if let error = error {
                print("Database write error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            postRef.child("commentCount").observeSingleEvent(of: .value) { snapshot in
                var newCommentCount = 0
                if let currentCount = snapshot.value as? Int {
                    newCommentCount = currentCount + 1
                } else {
                    newCommentCount = 1
                }
                
                postRef.child("commentCount").setValue(newCommentCount) { error, _ in
                    if let error = error {
                        print("Failed to update comment count: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        print("Comment uploaded and comment count updated successfully")
                        completion(.success(()))
                    }
                }
            }
        }
    }

    // Update the like count of a post
    static func updatePostLikeCount(postId: String, isIncrement: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        let postRef = db.child("posts").child(postId)

        postRef.child("likeCount").observeSingleEvent(of: .value) { snapshot in
            var newLikeCount = 0
            if let currentCount = snapshot.value as? Int {
                newLikeCount = isIncrement ? currentCount + 1 : max(currentCount - 1, 0)
            } else {
                newLikeCount = isIncrement ? 1 : 0
            }

            postRef.child("likeCount").setValue(newLikeCount) { error, _ in
                if let error = error {
                    print("Failed to update like count: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    // Delete a post
    static func deletePost(postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let postRef = db.child("posts").child(postId)

        postRef.observeSingleEvent(of: .value) { snapshot in
            guard let postData = snapshot.value as? [String: Any],
                  let postURLArray = postData["postURL"] as? [String],
                  let postURLString = postURLArray.first else {
                let error = NSError(domain: "com.yourdomain.yourapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "Post not found"])
                completion(.failure(error))
                return
            }

            let storageRef = storage.reference(forURL: postURLString)
            storageRef.delete { error in
                if let error = error {
                    print("Failed to delete image from storage: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                postRef.removeValue { error, _ in
                    if let error = error {
                        print("Failed to delete post from database: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        print("Post deleted successfully")

                        // Update the user's post count
                        decrementPostCount(for: UserState.shared.currentUserId ?? "") { result in
                            switch result {
                            case .success():
                                print("Post count updated successfully")
                                completion(.success(()))
                            case .failure(let error):
                                print("Failed to update post count: \(error.localizedDescription)")
                                completion(.failure(error))
                            }
                        }
                    }
                }
            }
        }
    }

    // Increment the post count for a user
    private static func incrementPostCount(for userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userRef = db.child("users").child(userId)
        userRef.child("postCount").observeSingleEvent(of: .value) { snapshot in
            var newPostCount = 0
            if let currentCount = snapshot.value as? Int {
                newPostCount = currentCount + 1
            } else {
                newPostCount = 1
            }

            userRef.child("postCount").setValue(newPostCount) { error, _ in
                if let error = error {
                    print("Failed to update post count: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    // Decrement the post count for a user
    private static func decrementPostCount(for userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userRef = db.child("users").child(userId)
        userRef.child("postCount").observeSingleEvent(of: .value) { snapshot in
            var newPostCount = 0
            if let currentCount = snapshot.value as? Int {
                newPostCount = max(currentCount - 1, 0)
            } else {
                newPostCount = 0
            }

            userRef.child("postCount").setValue(newPostCount) { error, _ in
                if let error = error {
                    print("Failed to update post count: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
}
