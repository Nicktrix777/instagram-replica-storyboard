//
//  AuthenticationHandler.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 19/07/24.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

class AuthenticationHandler {
    
    private static var ref: DatabaseReference = Database.database().reference()
    
    static func updateProfilePicture(profilePictureURL: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard SessionManager.shared.isLoggedIn, let userId = UserState.shared.profile?.userId else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }

        let updates: [String: Any] = ["profilePictureURL": profilePictureURL]
        let ref = self.ref

        ref.child("users").child(userId).updateChildValues(updates) { (error, _) in
            if let error = error {
                completion(.failure(error))
                return
            }

            // Update posts
            ref.child("posts").queryOrdered(byChild: "userId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot {
                        childSnapshot.ref.updateChildValues(updates)
                    }
                }

                // Update stories
                ref.child("stories").queryOrdered(byChild: "userId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
                    for child in snapshot.children {
                        if let childSnapshot = child as? DataSnapshot {
                            childSnapshot.ref.updateChildValues(updates)
                        }
                    }

                    // Update comments
                    ref.child("comments").queryOrdered(byChild: "userId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
                        for child in snapshot.children {
                            if let childSnapshot = child as? DataSnapshot {
                                childSnapshot.ref.updateChildValues(updates)
                            }
                        }

                        // Update local profile
                        if var profile = UserState.shared.profile {
                            profile.profilePictureURL = profilePictureURL
                            UserState.shared.profile = profile
                        }

                        completion(.success(()))
                    } withCancel: { error in
                        completion(.failure(error))
                    }
                } withCancel: { error in
                    completion(.failure(error))
                }
            } withCancel: { error in
                completion(.failure(error))
            }
        }
    }

    
    static func restoreUserSession(completion: @escaping (Result<Void, Error>) -> Void) {
        if let user = Auth.auth().currentUser {
            self.ref.child("users").child(user.uid).observeSingleEvent(of: .value) { snapshot in
                guard let userDict = snapshot.value as? [String: Any] else {
                    let error = NSError(domain: "com.yourdomain.yourapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "User details not found"])
                    completion(.failure(error))
                    return
                }
                
                let profile = ProfileModel(
                    userId: user.uid,
                    username: userDict["username"] as? String ?? "",
                    email: userDict["email"] as? String ?? "",
                    profilePictureURL: userDict["profilePictureURL"] as? String ?? "",
                    bio: userDict["bio"] as? String ?? "",
                    followerUserId: userDict["followerUserId"] as? [String] ?? [],
                    followingUserId: userDict["followingUserId"] as? [String] ?? [],
                    postCount: userDict["postCount"] as? Int ?? 0 // Changed from userPosts to postCount
                )
                
                UserState.shared.profile = profile
                SessionManager.shared.isLoggedIn = true
                completion(.success(()))
            }
        } else {
            UserState.shared.profile = nil
            SessionManager.shared.isLoggedIn = false
            completion(.failure(NSError(domain: "com.yourdomain.yourapp", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])))
        }
    }
    
    static func register(request: RegisterRequest, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: request.email, password: request.password) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user else {
                let error = NSError(domain: "com.yourdomain.yourapp", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create user"])
                completion(.failure(error))
                return
            }
            
            let userDict: [String: Any] = [
                "username": request.username,
                "email": request.email,
                "uid": user.uid,
                "postCount": 0 // Initialize postCount to 0
            ]
            
            self.ref.child("users").child(user.uid).setValue(userDict) { (error, ref) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let profile = ProfileModel(
                    userId: user.uid,
                    username: request.username,
                    email: request.email,
                    profilePictureURL: "",
                    bio: "",
                    followerUserId: [],
                    followingUserId: [],
                    postCount: 0 // Initialize postCount to 0
                )
                
                UserState.shared.profile = profile
                SessionManager.shared.isLoggedIn = true
                completion(.success(()))
            }
        }
    }
    
    static func login(request: LoginRequest, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: request.email, password: request.password) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user else {
                let error = NSError(domain: "com.yourdomain.yourapp", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to login"])
                completion(.failure(error))
                return
            }
            
            self.ref.child("users").child(user.uid).observeSingleEvent(of: .value) { snapshot in
                guard let userDict = snapshot.value as? [String: Any] else {
                    let error = NSError(domain: "com.yourdomain.yourapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "User details not found"])
                    completion(.failure(error))
                    return
                }
                
                let profile = ProfileModel(
                    userId: user.uid,
                    username: userDict["username"] as? String ?? "",
                    email: userDict["email"] as? String ?? "",
                    profilePictureURL: "",
                    bio: "",
                    followerUserId: userDict["followerUserId"] as? [String] ?? [],
                    followingUserId: userDict["followingUserId"] as? [String] ?? [],
                    postCount: userDict["postCount"] as? Int ?? 0 // Changed from userPosts to postCount
                )
                
                UserState.shared.profile = profile
                SessionManager.shared.isLoggedIn = true
                completion(.success(()))
            }
        }
    }
    
    static func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            UserState.shared.profile = nil
            SessionManager.shared.isLoggedIn = false
            completion(.success(()))
        } catch let error {
            completion(.failure(error))
        }
    }
    
    static func fetchUserDetails(userId: String, completion: @escaping (Result<ProfileModel, Error>) -> Void) {
        self.ref.child("users").child(userId).observeSingleEvent(of: .value) { snapshot in
            guard let userDict = snapshot.value as? [String: Any] else {
                let error = NSError(domain: "com.yourdomain.yourapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "User details not found"])
                completion(.failure(error))
                return
            }
            
            let profile = ProfileModel(
                userId: userId,
                username: userDict["username"] as? String ?? "",
                email: userDict["email"] as? String ?? "",
                profilePictureURL: userDict["profilePictureURL"] as? String ?? "",
                bio: userDict["bio"] as? String ?? "",
                followerUserId: userDict["followerUserId"] as? [String] ?? [],
                followingUserId: userDict["followingUserId"] as? [String] ?? [],
                postCount: userDict["postCount"] as? Int ?? 0 // Changed from userPosts to postCount
            )
            completion(.success(profile))
        }
    }
    
    static func updateUsername(newUsername: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard SessionManager.shared.isLoggedIn, let userId = UserState.shared.profile?.userId else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }
        
        let updates: [String: Any] = ["username": newUsername]
        let ref = self.ref
        
        ref.child("users").child(userId).updateChildValues(updates) { (error, _) in
            if let error = error {
                completion(.failure(error))
                return
            }

            // Update posts
            ref.child("posts").queryOrdered(byChild: "userId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot {
                        childSnapshot.ref.updateChildValues(updates)
                    }
                }
                
                // Update stories
                ref.child("stories").queryOrdered(byChild: "userId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
                    for child in snapshot.children {
                        if let childSnapshot = child as? DataSnapshot {
                            childSnapshot.ref.updateChildValues(updates)
                        }
                    }
                    
                    // Update comments
                    ref.child("comments").queryOrdered(byChild: "userId").queryEqual(toValue: userId).observeSingleEvent(of: .value) { snapshot in
                        for child in snapshot.children {
                            if let childSnapshot = child as? DataSnapshot {
                                childSnapshot.ref.updateChildValues(updates)
                            }
                        }

                        // Update local profile
                        if var profile = UserState.shared.profile {
                            profile.username = newUsername
                            UserState.shared.profile = profile
                        }

                        completion(.success(()))
                    } withCancel: { error in
                        completion(.failure(error))
                    }
                } withCancel: { error in
                    completion(.failure(error))
                }
            } withCancel: { error in
                completion(.failure(error))
            }
        }
    }

    
    
    static func updatePassword(newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard SessionManager.shared.isLoggedIn, let user = Auth.auth().currentUser else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }
        
        user.updatePassword(to: newPassword) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    static func updateBio(newBio: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard SessionManager.shared.isLoggedIn, let userId = UserState.shared.profile?.userId else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in"])
            completion(.failure(error))
            return
        }
        
        self.ref.child("users").child(userId).updateChildValues(["bio": newBio]) { (error, ref) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Update local profile
            if var profile = UserState.shared.profile {
                profile.bio = newBio
                UserState.shared.profile = profile
            }
            
            completion(.success(()))
        }
    }
    
    static func followUser(followingUserId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
            completion(.failure(error))
            return
        }
        
        let currentUserRef = ref.child("users").child(currentUserId)
        let followingUserRef = ref.child("users").child(followingUserId)
        
        // Update followingUserId in the current user's profile
        currentUserRef.child("followingUserId").observeSingleEvent(of: .value) { snapshot in
            var followingIds = snapshot.value as? [String] ?? []
            if !followingIds.contains(followingUserId) {
                followingIds.append(followingUserId)
                currentUserRef.child("followingUserId").setValue(followingIds)
            }
        }
        
        // Update followerUserId in the following user's profile
        followingUserRef.child("followerUserId").observeSingleEvent(of: .value) { snapshot in
            var followerIds = snapshot.value as? [String] ?? []
            if !followerIds.contains(currentUserId) {
                followerIds.append(currentUserId)
                followingUserRef.child("followerUserId").setValue(followerIds) { error, _ in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            } else {
                // Already following
                completion(.success(()))
            }
        }
    }
    
    static func unfollowUser(followingUserId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
            completion(.failure(error))
            return
        }
        
        let currentUserRef = ref.child("users").child(currentUserId)
        let followingUserRef = ref.child("users").child(followingUserId)
        
        // Update followingUserId in the current user's profile
        currentUserRef.child("followingUserId").observeSingleEvent(of: .value) { snapshot in
            var followingIds = snapshot.value as? [String] ?? []
            if let index = followingIds.firstIndex(of: followingUserId) {
                followingIds.remove(at: index)
                currentUserRef.child("followingUserId").setValue(followingIds)
            }
        }
        
        // Update followerUserId in the following user's profile
        followingUserRef.child("followerUserId").observeSingleEvent(of: .value) { snapshot in
            var followerIds = snapshot.value as? [String] ?? []
            if let index = followerIds.firstIndex(of: currentUserId) {
                followerIds.remove(at: index)
                followingUserRef.child("followerUserId").setValue(followerIds) { error, _ in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            } else {
                // Not following
                completion(.success(()))
            }
        }
    }
    
    static func isFollowing(userIdToCheck: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            completion(.failure(error))
            return
        }
        
        // Fetch the current user's profile to check the following list
        ref.child("users").child(currentUserId).observeSingleEvent(of: .value) { snapshot in
            guard let userDict = snapshot.value as? [String: Any],
                  let followingUserIds = userDict["followingUserId"] as? [String] else {
                let error = NSError(domain: "com.yourdomain.yourapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "User details not found"])
                completion(.failure(error))
                return
            }
            
            // Check if the userIdToCheck is in the followingUserIds list
            let isFollowing = followingUserIds.contains(userIdToCheck)
            completion(.success(isFollowing))
        }
    }
    
    static func searchUsers(username: String, completion: @escaping (Result<[ProfileModel], Error>) -> Void) {
        ref.child("users").queryOrdered(byChild: "username").queryStarting(atValue: username).queryEnding(atValue: username + "\u{f8ff}").observeSingleEvent(of: .value) { snapshot in
            var profiles: [ProfileModel] = []

            for child in snapshot.children {
                guard let snapshot = child as? DataSnapshot,
                      let userDict = snapshot.value as? [String: Any] else {
                    continue
                }

                let profile = ProfileModel(
                    userId: snapshot.key,
                    username: userDict["username"] as? String ?? "",
                    email: userDict["email"] as? String ?? "",
                    profilePictureURL: userDict["profilePictureURL"] as? String ?? "",
                    bio: userDict["bio"] as? String ?? "",
                    followerUserId: userDict["followerUserId"] as? [String] ?? [],
                    followingUserId: userDict["followingUserId"] as? [String] ?? [],
                    postCount: userDict["postCount"] as? Int ?? 0 // Changed from userPosts to postCount
                )

                profiles.append(profile)
            }

            completion(.success(profiles))
        } withCancel: { error in
            completion(.failure(error))
        }
    }

    // New method to increment postCount when a new post is added
    static func incrementPostCount(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        ref.child("users").child(userId).child("postCount").observeSingleEvent(of: .value) { snapshot in
            let currentCount = snapshot.value as? Int ?? 0
            let newCount = currentCount + 1
            
            ref.child("users").child(userId).updateChildValues(["postCount": newCount]) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // New method to decrement postCount when a post is deleted (if needed)
    static func decrementPostCount(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        ref.child("users").child(userId).child("postCount").observeSingleEvent(of: .value) { snapshot in
            let currentCount = snapshot.value as? Int ?? 0
            let newCount = max(currentCount - 1, 0)
            
            ref.child("users").child(userId).updateChildValues(["postCount": newCount]) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
}
