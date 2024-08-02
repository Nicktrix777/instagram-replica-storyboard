//
//  CommentModel.swift
//  PicSphere
//
//  Created by Shamanth Keni on 25/07/24.
//

struct CommentModel {
    var commentId: String
    var postId: String
    var userId: String
    var username: String
    var profilePictureURL: String
    var commentText: String

    // This initializer is useful to create a CommentModel from a dictionary
    init?(dictionary: [String: Any]) {
        guard let commentId = dictionary["commentId"] as? String,
              let postId = dictionary["postId"] as? String,
              let userId = dictionary["userId"] as? String,
              let username = dictionary["username"] as? String,
              let profilePictureURL = dictionary["profilePictureURL"] as? String,
              let commentText = dictionary["commentText"] as? String else { return nil }

        self.commentId = commentId
        self.postId = postId
        self.userId = userId
        self.username = username
        self.profilePictureURL = profilePictureURL
        self.commentText = commentText
    }

    // This initializer directly sets the properties
    init(commentId: String, postId: String, userId: String, username: String, profilePictureURL: String, commentText: String) {
        self.commentId = commentId
        self.postId = postId
        self.userId = userId
        self.username = username
        self.profilePictureURL = profilePictureURL
        self.commentText = commentText
    }

    func toDictionary() -> [String: Any] {
        return [
            "commentId": commentId,
            "postId": postId,
            "userId": userId,
            "username": username,
            "profilePictureURL": profilePictureURL,
            "commentText": commentText
        ]
    }
}
