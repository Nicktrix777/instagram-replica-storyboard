//
//  HomeViewController.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 19/07/24.
//


import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var storiesCollection: UICollectionView!
    @IBOutlet weak var postsTable: UITableView!
    
    private let viewModel = HomeViewModel()
    
    private let tableRefreshControl = UIRefreshControl()
    private let collectionRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRefreshControls()
        fetchData()
    }
    
    private func setupUI() {
        setupTable()
        setupCollection()
    }
    
    private func setupTable() {
        postsTable.delegate = self
        postsTable.dataSource = self
        postsTable.register(ProfileTableViewCell.nib(), forCellReuseIdentifier: ProfileTableViewCell.identifier)
        postsTable.allowsSelection = false
    }
    
    private func setupCollection() {
        storiesCollection.delegate = self
        storiesCollection.dataSource = self
        storiesCollection.register(StoriesCollectionViewCell.nib(), forCellWithReuseIdentifier: StoriesCollectionViewCell.identifier)
        storiesCollection.showsHorizontalScrollIndicator = false
    }
    
    private func setupRefreshControls() {
        // Setup refresh control for table view
        tableRefreshControl.addTarget(self, action: #selector(refreshTableData), for: .valueChanged)
        postsTable.refreshControl = tableRefreshControl
        
        // Setup refresh control for collection view
        collectionRefreshControl.addTarget(self, action: #selector(refreshCollectionData), for: .valueChanged)
        storiesCollection.refreshControl = collectionRefreshControl
    }
    
    @objc private func refreshTableData() {
        fetchData()
    }
    
    @objc private func refreshCollectionData() {
        fetchData()
    }
    
    private func fetchData() {
        viewModel.fetchData { [weak self] result in
            DispatchQueue.main.async {
                self?.tableRefreshControl.endRefreshing()
                self?.collectionRefreshControl.endRefreshing()
                
                switch result {
                case .success:
                    self?.postsTable.reloadData()
                    self?.storiesCollection.reloadData()
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                }
            }
        }
    }
    
    private func navigateToProfile(with userId: String) {
        DispatchQueue.main.async {
            let vc = UIStoryboard(name: "Authenticated", bundle: nil).instantiateViewController(withIdentifier: "ViewProfileViewController") as! ViewProfileViewController
            vc.userId = userId
            vc.isNavigated = true // Enable swipe gesture for dismissal
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    private func navigateToStory(story: StoryModel) {
        let vc = UIStoryboard(name: "Authenticated", bundle: nil).instantiateViewController(withIdentifier: "StoryViewController") as! StoryViewController
        vc.storyItems = story
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfPosts()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        let post = viewModel.post(at: indexPath.row)
        cell.deletePostButton.isHidden = true // Ensure delete button is hidden
        cell.configure(with: post)
        return cell
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 375.0
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let userId = viewModel.selectedUserId(forPostAt: indexPath.row) else { return }
        navigateToProfile(with: userId)
    }
}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfStories()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = storiesCollection.dequeueReusableCell(withReuseIdentifier: StoriesCollectionViewCell.identifier, for: indexPath) as! StoriesCollectionViewCell
        let story = viewModel.story(at: indexPath.row)
        cell.configure(story: story)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 75, height: 75)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let story = viewModel.story(at: indexPath.row)
        navigateToStory(story: story)
    }
}
