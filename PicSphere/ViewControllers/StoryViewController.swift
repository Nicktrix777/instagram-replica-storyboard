//
//  StoryViewController.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 24/07/24.
//

import UIKit
import Kingfisher

class StoryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var storyPostCollection: UICollectionView!

    var storyItems: StoryModel = StoryModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollection()
        setupSwipeGesture()
        username.text = storyItems.username
    }

    func setupSwipeGesture() {
        let dismissStorySwipe = UISwipeGestureRecognizer(target: self, action: #selector(dismissStory(_:)))
        dismissStorySwipe.direction = .down
        storyPostCollection.addGestureRecognizer(dismissStorySwipe)
    }

    @objc func dismissStory(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == .down {
            self.dismiss(animated: true, completion: nil)
        }
    }

    func setupCollection() {
        storyPostCollection.delegate = self
        storyPostCollection.dataSource = self
        storyPostCollection.allowsSelection = false
        storyPostCollection.showsHorizontalScrollIndicator = false
        storyPostCollection.register(StoryCollectionViewCell.nib(), forCellWithReuseIdentifier: StoryCollectionViewCell.identifier)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return storyItems.storyPostURL?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = storyPostCollection.dequeueReusableCell(withReuseIdentifier: StoryCollectionViewCell.identifier, for: indexPath) as! StoryCollectionViewCell
        
        // Ensure storyPostURL is not nil and valid
        guard let urlString = storyItems.storyPostURL?[indexPath.row], let url = URL(string: urlString) else {
            // Handle error or placeholder image if URL is invalid
            cell.storyPost.image = UIImage(named: "placeholder") // Provide a placeholder image
            return cell
        }
        
        // Use Kingfisher to load image asynchronously without completion handler
        cell.storyPost.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"))
        
        return cell
    }
}
