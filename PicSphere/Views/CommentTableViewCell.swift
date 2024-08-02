//
//  CommentTableViewCell.swift
//  PicSphere
//
//  Created by Shamanth Keni on 25/07/24.
//

import UIKit
import Kingfisher

class CommentTableViewCell: UITableViewCell {

    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!

    static func nib() -> UINib {
        return UINib(nibName: "CommentTableViewCell", bundle: nil)
    }

    static let identifier = "comment"

    override func awakeFromNib() {
        super.awakeFromNib()
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
        profilePicture.layer.masksToBounds = true
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(comment: CommentModel) {
        // Use Kingfisher to set the image from URL
        if let url = URL(string: comment.profilePictureURL) {
            profilePicture.kf.setImage(with: url)
        } else {
            profilePicture.image = UIImage(named: "defaultProfilePicture") // Optional: Use a default image if URL is invalid
        }
        
        username.text = comment.username
        commentLabel.text = comment.commentText
    }
}

