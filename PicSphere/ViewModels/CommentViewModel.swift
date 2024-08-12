//
//  CommentViewModel.swift
//  PicSphere
//
//  Created by Shamanth Keni on 25/07/24.
//

import Foundation

class CommentViewModel {
    
    var comments: [CommentModel] = []
    
    func fetchComments(postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        PostsHandler.fetchComments(for: postId) { result in
            switch result {
            case .success(let comments):
                self.comments = comments
                completion(.success(()))
            case .failure(let error):
                print("\(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func numberOfComments() -> Int {
        return comments.count
    }
    
    func comment(at index: Int) -> CommentModel {
        guard index >= 0 && index < comments.count else {
            fatalError("Index out of bounds")
        }
        return comments[index]
    }
    
    func username(for index: Int) -> String? {
        guard index >= 0 && index < comments.count else {
            return nil
        }
        return comments[index].username
    }
    
    func profilePictureURL(for index: Int) -> String? {
        guard index >= 0 && index < comments.count else {
            return nil
        }
        return comments[index].profilePictureURL
    }
    
    func commentText(for index: Int) -> String? {
        guard index >= 0 && index < comments.count else {
            return nil
        }
        return comments[index].commentText
    }
    
    func uploadComment(commentText: String, postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Ensure that the user is logged in
        guard let userId = UserState.shared.currentUserId else {
            let error = NSError(domain: "com.yourdomain.yourapp", code: 401, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in"])
            completion(.failure(error))
            return
        }
        

        PostStorageHandler.uploadComment(postId: postId, commentText: commentText) { result in
            switch result {
            case .success:
                
                let newComment = CommentModel(
                    commentId: UUID().uuidString,
                    postId: postId,
                    userId: userId,
                    username: UserState.shared.profile?.username ?? "",
                    profilePictureURL: UserState.shared.profile?.profilePictureURL ?? "",
                    commentText: commentText
                )
                self.comments.append(newComment)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
