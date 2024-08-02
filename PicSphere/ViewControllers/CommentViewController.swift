//
//  CommentViewController.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 23/07/24.
//

import UIKit
import Kingfisher

class CommentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var commentsTable: UITableView!
    @IBOutlet weak var addCommentTextField: UITextField!
    @IBOutlet weak var profilePicture: UIImageView!

    let commentViewModel = CommentViewModel()
    var postId: String = ""  // Set this value from the previous view controller

    override func viewDidLoad() {
        super.viewDidLoad()
        let pfp = UserState.shared.profile?.profilePictureURL
        let url = URL(string: pfp!)
        profilePicture.kf.setImage(with: url)
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
        profilePicture.layer.masksToBounds = true
        setupTable()
        fetchComments()
    }

    private func setupTable() {
        commentsTable.delegate = self
        commentsTable.dataSource = self
        commentsTable.register(CommentTableViewCell.nib(), forCellReuseIdentifier: CommentTableViewCell.identifier)
    }

    private func fetchComments() {
        commentViewModel.fetchComments(postId: postId) { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.commentsTable.reloadData()
                }
            case .failure(let error):
                print("Failed to fetch comments: \(error.localizedDescription)")
                // Handle error
            }
        }
    }

    @IBAction func sendComment(_ sender: Any) {
        // Ensure the text field is not empty
           guard let commentText = addCommentTextField.text, !commentText.isEmpty else {
               // Create and configure the alert
               let alert = UIAlertController(title: "Empty Comment", message: "Please enter a comment before sending.", preferredStyle: .alert)
               let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
               alert.addAction(okAction)
               
               // Present the alert
               present(alert, animated: true, completion: nil)
               return
           }

           // Call the view model to upload the comment
           commentViewModel.uploadComment(commentText: commentText, postId: postId) { [weak self] result in
               switch result {
               case .success:
                   DispatchQueue.main.async {
                       // Clear the text field
                       self?.addCommentTextField.text = ""
                       
                       // Reload the table view to display the new comment
                       self?.fetchComments()
                   }
               case .failure(let error):
                   DispatchQueue.main.async {
                       // Create and configure the alert for failure
                       let alert = UIAlertController(title: "Upload Failed", message: "Failed to upload comment: \(error.localizedDescription)", preferredStyle: .alert)
                       let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                       alert.addAction(okAction)
                       
                       // Present the alert
                       self?.present(alert, animated: true, completion: nil)
                   }
               }
           }
        
    }
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentViewModel.numberOfComments()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = commentsTable.dequeueReusableCell(withIdentifier: CommentTableViewCell.identifier, for: indexPath) as! CommentTableViewCell
        let comment = commentViewModel.comment(at: indexPath.row)
        cell.configure(comment: comment)
        return cell
    }
    

    

    // MARK: - UITableViewDelegate

    // Implement any UITableViewDelegate methods if needed

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}
