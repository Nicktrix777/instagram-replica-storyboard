//
//  ProfileModel.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 23/07/24.
//

import Foundation

struct ProfileModel:Codable {
    
    var userId: String
    var username: String
    var email: String
    var profilePictureURL: String?
    var bio: String
    var followerUserId: [String]
    var followingUserId: [String]
    var postCount:Int
    
    var followerCount: Int {
        return followerUserId.count
    }
    
    var followingCount: Int {
        return followingUserId.count
    }
    
    init(userId: String, username: String,email: String, profilePictureURL: String, bio: String, followerUserId: [String] = [], followingUserId: [String] = [], postCount: Int) {
        
        self.userId = userId
        self.username = username
        self.email = email
        self.profilePictureURL = profilePictureURL
        self.bio = bio
        self.followerUserId = followerUserId
        self.followingUserId = followingUserId
        self.postCount = postCount
        
    }
    
    init() {
        self.userId = ""
        self.username = ""
        self.email = ""
        self.profilePictureURL = ""
        self.bio = ""
        self.followerUserId = []
        self.followingUserId = []
        self.postCount = 0
    }
}

