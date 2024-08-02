//
//  StoriesCollectionViewCell.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 19/07/24.
//

import UIKit

class StoriesCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var username: UILabel!
    
    static let identifier = "story"
    
    static func nib() -> UINib {
        return UINib(nibName: "StoriesCollectionViewCell", bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        // Initialization code
    }
    
    func setupUI() {
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
        profilePicture.layer.masksToBounds = true
        profilePicture.isUserInteractionEnabled = true
        profilePicture.layer.borderColor = UIColor.cyan.cgColor
        profilePicture.layer.borderWidth = 1
        profilePicture.contentMode = .scaleAspectFill
    }
    
    func configure(story: StoryModel) {
            // Load profile picture using Kingfisher
        DispatchQueue.main.async {
            if let profilePictureURL = URL(string: story.profilePictureURL) {
                print("\(profilePictureURL)")
                self.profilePicture.kf.setImage(with: profilePictureURL, placeholder: UIImage(named: "placeholder"))
            } else {
                self.profilePicture.image = UIImage(named: "placeholder")
            }
        }
            // Set the username
            self.username.text = story.username
        }

}
