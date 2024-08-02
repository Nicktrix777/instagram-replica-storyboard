//
//  StoryCollectionViewCell.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 24/07/24.
//

import UIKit

class StoryCollectionViewCell: UICollectionViewCell {

    static let identifier = "storyView"
    
    @IBOutlet weak var storyPost: UIImageView!
        
    static func nib() -> UINib {
        return UINib(nibName: "StoryCollectionViewCell", bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
