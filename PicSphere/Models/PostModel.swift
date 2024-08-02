//
//  PostModel.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 22/07/24.
//

struct PostModel:Codable {
    var postId: String
    var userId: String
    var username: String
    var profilePictureURL: String
    var postURL: [String]?
    var commentCount: Int
    var likeCount: Int
    
    func toDictionary() -> [String: Any] {
         return [
             "postId": postId,
             "userId": userId,
             "username": username,
             "profilePictureURL": profilePictureURL,
             "postURL": postURL ?? [],
             "commentCount": commentCount,
             "likeCount": likeCount
         ]
     }
    
}
