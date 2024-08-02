//
//  PostsCollectionViewCell.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 19/07/24.
//

import UIKit

class PostsCollectionViewCell: UICollectionViewCell {

    
    @IBOutlet weak var post: UIImageView!
    
    static let identifier = "posts"
    
    static func nib() -> UINib {
        return UINib(nibName: "PostsCollectionViewCell", bundle: nil)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
