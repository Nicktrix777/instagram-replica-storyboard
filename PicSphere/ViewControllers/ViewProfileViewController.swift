//
//  ViewProfileViewController.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 23/07/24.
//

import UIKit
import FirebaseAuth

class ViewProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var postsCount: UILabel!
    @IBOutlet weak var followingCount: UILabel!
    @IBOutlet weak var followerCount: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var postsTable: UITableView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    private let viewProfileViewModel = ViewProfileViewModel()
    private let refreshControl = UIRefreshControl() // Step 1: Add a UIRefreshControl instance
    
    var userId: String?
    var isNavigated: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        DispatchQueue.main.async {
            self.setupProfilePicture()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchProfileData()
        DispatchQueue.main.async {
            self.setupProfilePicture()
        }
    }
    
    func setupUI() {
        setupTable()
        if isNavigated {
            setupDismissSwipe()
        }
        // Keep this call to setup the profile picture initially
    }
    
    func setupDismissSwipe() {
        let dismissSwipe = UISwipeGestureRecognizer(target: self, action: #selector(dismissView(_:)))
        dismissSwipe.direction = .down
        self.view.addGestureRecognizer(dismissSwipe)
    }
    
    @objc func dismissView(_ sender: UISwipeGestureRecognizer) {
        self.dismiss(animated: true)
    }
    
    func setupTable() {
        postsTable.delegate = self
        postsTable.dataSource = self
        postsTable.register(ProfileTableViewCell.nib(), forCellReuseIdentifier: ProfileTableViewCell.identifier)
        postsTable.allowsSelection = false
        
        // Step 2: Add and configure the refresh control
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        postsTable.refreshControl = refreshControl
    }
    
    @objc func refreshData() {
        fetchProfileData()
    }
    
    func fetchProfileData() {
        let targetUserId: String
        
        if let userId = userId {
            targetUserId = userId
        } else {
            guard let currentUser = Auth.auth().currentUser else {
                fatalError("No user is logged in")
            }
            targetUserId = currentUser.uid
        }
        
        viewProfileViewModel.fetchProfileDetails(userId: targetUserId) { [weak self] result in
            switch result {
            case .success(let profile):
                self?.populateUserInfo(with: profile)
                self?.fetchProfilePosts()
            case .failure(let error):
                print("Error fetching profile details \(error.localizedDescription)")
            }
        }
    }
    
    func fetchProfilePosts() {
        guard let userId = userId ?? Auth.auth().currentUser?.uid else {
            return
        }
        viewProfileViewModel.fetchProfilePosts(userId: userId) { [weak self] result in
            switch result {
            case .success:
                self?.updatePostsTable()
            case .failure(let error):
                print("Error fetching posts \(error.localizedDescription)")
            }
        }
    }
    
    func populateUserInfo(with profile: ProfileModel) {
        DispatchQueue.main.async { [weak self] in
            self?.username.text = profile.username
            print("bio\(profile)")
            self?.descriptionLabel.text = profile.bio
            self?.postsCount.text = "\(profile.postCount)"
            self?.followerCount.text = "\(profile.followerCount)"
            self?.followingCount.text = "\(profile.followingCount)"
            self?.updateFollowButtonTitle()
            self?.refreshControl.endRefreshing() // End the refresh control animation
        }
    }
    
    func setupProfilePicture() {
        guard let profilePictureURL = UserState.shared.profile?.profilePictureURL else {
            return
        }
        print("profile picture id in view controller: \(profilePictureURL)")
        let userProfilePictureURL = URL(string:profilePictureURL)
        profilePicture.kf.setImage(with: userProfilePictureURL)
        profilePicture.layer.cornerRadius = profilePicture.frame.height / 2
        profilePicture.contentMode = .scaleAspectFill
        profilePicture.layer.masksToBounds = true
        // Profile picture will be set in populateUserInfo, but initial setup is here
    }
    
    func updateFollowButtonTitle() {
        guard let profileDetails = viewProfileViewModel.getProfileDetails() else {
            return
        }
        
        viewProfileViewModel.isFollowing(profileUserId: profileDetails.userId) { [weak self] isFollowing in
            DispatchQueue.main.async {
                if isFollowing {
                    self?.followButton.layer.borderColor = UIColor.label.cgColor
                    self?.followButton.layer.borderWidth = 1
                    self?.followButton.tintColor = .systemBackground
                    self?.followButton.setTitle("Following", for: .normal)
                } else {
                    self?.followButton.layer.borderWidth = 0
                    self?.followButton.tintColor = .systemBlue
                    self?.followButton.setTitle("Follow", for: .normal)
                }
            }
        }
    }
    
    func updatePostsTable() {
        postsTable.reloadData()
    }
    
    @IBAction func followButtonPressed(_ sender: Any) {
        guard let profileDetails = viewProfileViewModel.getProfileDetails() else {
            return
        }
        
        if followButton.titleLabel?.text == "Follow" {
            viewProfileViewModel.followUser(userId: profileDetails.userId) { [weak self] result in
                switch result {
                case .success:
                    let currentCount = Int(self?.followerCount.text ?? "0") ?? 0
                    self?.followerCount.text = "\(currentCount + 1)"
                    self?.updateFollowButtonTitle()
                case .failure(let error):
                    print("Error following user \(error.localizedDescription)")
                }
            }
        } else if followButton.titleLabel?.text == "Following" {
            viewProfileViewModel.unfollowUser(userId: profileDetails.userId) { [weak self] result in
                switch result {
                case .success:
                    let currentCount = Int(self?.followerCount.text ?? "0") ?? 0
                    self?.followerCount.text = "\(currentCount - 1)"
                    self?.updateFollowButtonTitle()
                case .failure(let error):
                    print("Error unfollowing user \(error.localizedDescription)")
                }
            }
        }
    }
    
    // TableView DataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewProfileViewModel.numberOfPosts()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        
        let post = viewProfileViewModel.post(at: indexPath.row)
        if isNavigated{
            cell.deletePostButton.isHidden = true
        }
        cell.configure(with: post)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Handle cell selection if needed
    }
}
