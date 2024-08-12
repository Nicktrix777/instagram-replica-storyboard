//
//  ProfileTableViewCell.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 19/07/24.
//

import UIKit
import Kingfisher

class ProfileTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var postsCollection: UICollectionView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var likeCount: UILabel!
    @IBOutlet weak var commentCount: UILabel!
    @IBOutlet weak var likeButton: UIImageView!
    @IBOutlet weak var commentButton: UIImageView!
    @IBOutlet weak var deletePostButton: UIImageView!

    static let identifier = "ProfileTableViewCell"
    
    var delegate:ProfileTableViewCellDelegate?
    var data: [String] = []
    var postData: PostModel?
    private var isLiked: Bool = false

    static func nib() -> UINib {
        return UINib(nibName: "ProfileTableViewCell", bundle: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    func setupUI() {
        profilePictureSetup()
        setupGestures()
        setupCollection()
        deletePostButton.isHidden = false
    }

    func setupCollection() {
        postsCollection.dataSource = self
        postsCollection.delegate = self
        postsCollection.register(PostsCollectionViewCell.nib(), forCellWithReuseIdentifier: PostsCollectionViewCell.identifier)
        postsCollection.showsHorizontalScrollIndicator = false
    }

    func configure(with post: PostModel) {
        postData = post
        setupProfileNavigation(with: post)
        self.data = post.postURL ?? []
        self.username.text = post.username
        
        // Load profile picture using Kingfisher
        if let profilePictureURL = URL(string: post.profilePictureURL) {
            profilePicture.kf.setImage(with: profilePictureURL, placeholder: UIImage(named: "default"))
        } else {
            profilePicture.image = UIImage(named: "default")
        }
        
        self.likeCount.text = "\(post.likeCount)"
        self.commentCount.text = "\(post.commentCount)"
        self.postsCollection.reloadData()

        // Update the like button state
        updateLikeButton()
    }

    func setupProfileNavigation(with post: PostModel) {
        if post.userId != UserState.shared.profile?.userId {
            profilePicture.isUserInteractionEnabled = true
            let profileGesture = UITapGestureRecognizer(target: self, action: #selector(navigateToProfile(_:)))
            profilePicture.addGestureRecognizer(profileGesture)
            username.isUserInteractionEnabled = true
            username.addGestureRecognizer(profileGesture)
        }
    }

    @objc func navigateToProfile(_ sender: UITapGestureRecognizer) {
        let vc = UIStoryboard(name: "Authenticated", bundle: nil).instantiateViewController(withIdentifier: "ViewProfileViewController") as! ViewProfileViewController
        NavigationHelper.presentVcModally(vc: vc, style: .fullScreen)
    }

    func setupGestures() {
        let likeGesture = UITapGestureRecognizer(target: self, action: #selector(likePost(_:)))
        likeButton.isUserInteractionEnabled = true
        likeButton.addGestureRecognizer(likeGesture)

        let commentGesture = UITapGestureRecognizer(target: self, action: #selector(commentPost(_:)))
        commentButton.isUserInteractionEnabled = true
        commentButton.addGestureRecognizer(commentGesture)

        let deleteGesture = UITapGestureRecognizer(target: self, action: #selector(deletePost(_:)))
        deletePostButton.isUserInteractionEnabled = true
        deletePostButton.addGestureRecognizer(deleteGesture)
    }

    @objc func deletePost(_ sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: "Delete Post", message: "Are you sure you want to delete this post?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
            self.deletePostFromServer()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if let viewController = self.parentViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
    }

    func deletePostFromServer() {
        guard let postId = postData?.postId else { return }

        PostStorageHandler.deletePost(postId: postId) { result in
            switch result {
            case .success:
                // Remove the post from the local data source
                self.removePostFromLocalDataSource()
                DispatchQueue.main.async {
                    // Reload collection view data or handle UI update if needed
                    self.delegate?.reloadPostsTable()
                }
            case .failure(let error):
                print("Failed to delete post: \(error.localizedDescription)")
                // Optionally show an alert to the user
                DispatchQueue.main.async {
                    let errorAlert = UIAlertController(title: "Error", message: "Failed to delete the post. Please try again later.", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.parentViewController?.present(errorAlert, animated: true, completion: nil)
                }
            }
        }
    }

    func removePostFromLocalDataSource() {
        guard let indexPath = self.postsCollection.indexPathsForVisibleItems.first else { return }
        data.remove(at: indexPath.row)
        postsCollection.performBatchUpdates({
            postsCollection.deleteItems(at: [indexPath])
        }, completion: nil)
        
    }

    @objc func likePost(_ sender: UITapGestureRecognizer) {
        guard let postId = postData?.postId else { return }

        if isLiked {
            PostsHandler.removeLike(fromPostId: postId) { result in
                switch result {
                case .success:
                    self.isLiked = false
                    self.updateLikeButton()
                    self.updateLikeCount(isIncrement: false)
                case .failure(let error):
                    print("Failed to unlike post: \(error.localizedDescription)")
                }
            }
        } else {
            PostsHandler.addLike(toPostId: postId) { result in
                switch result {
                case .success:
                    self.isLiked = true
                    self.updateLikeButton()
                    self.updateLikeCount(isIncrement: true)
                case .failure(let error):
                    print("Failed to like post: \(error.localizedDescription)")
                }
            }
        }
    }

    func updateLikeButton() {
        if isLiked {
            likeButton.image = UIImage(systemName: "heart.fill")
            likeButton.tintColor = .red
        } else {
            likeButton.image = UIImage(systemName: "heart")
            likeButton.tintColor = .label
        }
    }

    func updateLikeCount(isIncrement: Bool) {
        guard let currentCount = Int(likeCount.text ?? "0") else { return }
        let newCount = isIncrement ? currentCount + 1 : max(currentCount - 1, 0)
        likeCount.text = "\(newCount)"
    }

    @objc func commentPost(_ sender: UITapGestureRecognizer) {
        let commentVC = UIStoryboard(name: "Authenticated", bundle: nil).instantiateViewController(withIdentifier: "CommentViewController") as! CommentViewController
        guard let postId = postData?.postId else { return }
        commentVC.postId = postId
        NavigationHelper.presentVcModally(vc: commentVC)
    }

    func profilePictureSetup() {
        profilePicture.layer.cornerRadius = profilePicture.frame.height / 2
        profilePicture.contentMode = .scaleAspectFill
        profilePicture.layer.masksToBounds = true
        profilePicture.isUserInteractionEnabled = true
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = postsCollection.dequeueReusableCell(withReuseIdentifier: PostsCollectionViewCell.identifier, for: indexPath) as! PostsCollectionViewCell

        // Load post image using Kingfisher
        if let postImageURL = URL(string: data[indexPath.row]) {
            cell.post.kf.setImage(with: postImageURL, placeholder: UIImage(named: "default"))
        } else {
            cell.post.image = UIImage(named: "default")
        }

        cell.post.contentMode = .scaleAspectFit
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 400, height: 400)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Handle item selection if needed
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while let responder = parentResponder {
            parentResponder = responder.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

protocol ProfileTableViewCellDelegate: AnyObject {
    func reloadPostsTable()
}
