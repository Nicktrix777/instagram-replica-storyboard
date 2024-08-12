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

    // Upload or replace a profile picture
    static func uploadProfilePicture(imageURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUserId = UserState.shared.currentUserId else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
            completion(.failure(error))
            return
        }

        // Check if there's an existing profile picture URL
        db.child("users").child(currentUserId).observeSingleEvent(of: .value) { snapshot in
            guard let userDict = snapshot.value as? [String: Any],
                  let currentProfilePictureURL = userDict["profilePictureURL"] as? String, !currentProfilePictureURL.isEmpty else {
                // No existing profile picture, just upload the new one
                uploadNewProfilePicture(imageURL: imageURL, completion: completion)
                return
            }

            // Delete the old profile picture if it exists
            let oldProfilePictureRef = storage.reference(forURL: currentProfilePictureURL)
            oldProfilePictureRef.delete { error in
                if let error = error {
                    print("Failed to delete old profile picture: \(error.localizedDescription)")
                }

                // Upload the new profile picture
                uploadNewProfilePicture(imageURL: imageURL, completion: completion)
            }
        }
    }

    // Upload a new profile picture and update the URL in the database
    private static func uploadNewProfilePicture(imageURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
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

                // Update profile picture URL in the database
                AuthenticationHandler.updateProfilePicture(profilePictureURL: downloadURL.absoluteString) { result in
                    switch result {
                    case .success():
                        completion(.success(downloadURL.absoluteString))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // Increment the post count for a user
    private static func incrementPostCount(for userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userRef = db.child("users").child(userId)

        userRef.observeSingleEvent(of: .value) { snapshot in
            guard var userData = snapshot.value as? [String: Any],
                  let currentPostCount = userData["postCount"] as? Int else {
                let error = NSError(domain: "com.yourdomain.yourapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "User data not found"])
                completion(.failure(error))
                return
            }

            userData["postCount"] = currentPostCount + 1
            userRef.updateChildValues(userData) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // Upload a new comment
    static func uploadComment(postId: String, commentText: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Ensure that the user is logged in
        guard let userId = UserState.shared.currentUserId else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
            completion(.failure(error))
            return
        }

        // Generate a unique comment ID
        let commentId = UUID().uuidString

        // Create a new comment model
        let newComment = CommentModel(
            commentId: commentId,
            postId: postId,
            userId: userId,
            username: UserState.shared.profile?.username ?? "",
            profilePictureURL: UserState.shared.profile?.profilePictureURL ?? "",
            commentText: commentText
        )

        // Reference to the comments node in the database
        let commentsRef = db.child("comments").child(commentId)
        
        // Convert CommentModel to dictionary
        let commentDict = newComment.toDictionary()

        // Save the comment to the database
        commentsRef.setValue(commentDict) { error, _ in
            if let error = error {
                print("Failed to upload comment: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            print("Comment uploaded successfully")

            // Update the comment count on the post
            updateCommentCount(for: postId) { result in
                switch result {
                case .success():
                    print("Comment count updated successfully")
                    completion(.success(()))
                case .failure(let error):
                    print("Failed to update comment count: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    // Update the comment count for a post
    private static func updateCommentCount(for postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let postRef = db.child("posts").child(postId)

        postRef.observeSingleEvent(of: .value) { snapshot in
            guard var postData = snapshot.value as? [String: Any],
                  let currentCommentCount = postData["commentCount"] as? Int else {
                let error = NSError(domain: "com.yourdomain.yourapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "Post data not found"])
                completion(.failure(error))
                return
            }

            postData["commentCount"] = currentCommentCount + 1
            postRef.updateChildValues(postData) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    static func updatePostCount(postCount:Int,completion: @escaping (Result<Void,Error>) -> Void) {
        print("updatePostCount hit")
        guard let currentUserId = UserState.shared.currentUserId else {
            print("updatePostCount failed to fetch currentUserId")
            return
        }
        print("updatePostCount fetched currentUserId succesfully")
        let usersRef = db.child("users").child(currentUserId)
        usersRef.observeSingleEvent(of: .value) { snapshot in
            guard var userData = snapshot.value as? [String: Any] else {
                print("updatePostCount failed to fetch fetch snapshot")
                return
            }
            print("updatePostCount succesfully fetched the snapshot \(userData)")
            userData["postCount"] = postCount
            usersRef.updateChildValues(userData) { error, _ in
                if let error = error {
                    print("updatePostCount error in updating values")
                    completion(.failure(error))
                } else {
                    print("updatePostCount successfully updated post count")
                    completion(.success(()))
                }
            }
        }
        
    }
    

    // Delete a post from the server
    static func deletePost(postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Reference to the post in the database
        let postRef = db.child("posts").child(postId)
        
        // Delete the post's image from storage
        let storageRef = storage.reference().child("posts/\(postId).png")

        // Delete the image from Firebase Storage
        storageRef.delete { error in
            if let error = error {
                // Handle the error if the image could not be deleted
                print("Failed to delete post image: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            // Delete the post data from Firebase Realtime Database
            postRef.removeValue { error, _ in
                if let error = error {
                    // Handle the error if the post data could not be deleted
                    print("Failed to delete post data: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                print("Post and associated data deleted successfully")
                completion(.success(()))
            }
        }
    }
    
}
