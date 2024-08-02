//
//  StoryModel.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 23/07/24.
//

import Foundation

struct StoryModel: Codable {
    
    var storyPostId: String
    var userId: String
    var profilePictureURL: String
    var username: String
    var storyPostURL: [String]?
    
    init(storyPostId: String, userId: String, profilePictureURL: String, username: String, storyPostURL: [String]) {
        self.storyPostId = storyPostId
        self.userId = userId
        self.profilePictureURL = profilePictureURL
        self.username = username
        self.storyPostURL = storyPostURL
    }
    
    init() {
        self.storyPostId = ""
        self.userId = ""
        self.profilePictureURL = ""
        self.username = ""
        self.storyPostURL = []
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "storyPostId": storyPostId,
            "userId": userId,
            "profilePictureURL": profilePictureURL,
            "username": username,
            "storyPostURL": storyPostURL ?? []
        ]
    }
}
