//
//  SearchViewController.swift
//  PicSphere
//
//  Created by Shamanth Keni on 25/07/24.
//

import UIKit

class SearchViewController: UIViewController {

    @IBOutlet weak var StatusLabel: UILabel!
    
    @IBOutlet weak var searchTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        StatusLabel.isHidden = true

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func searchPressed(_ sender: Any) {
        StatusLabel.isHidden = true
         guard let username = searchTF.text, !username.isEmpty else {
             StatusLabel.text = "Enter A Valid Username"
             StatusLabel.isHidden = false
             return
         }
         AuthenticationHandler.searchUsers(username: username) { result in
             DispatchQueue.main.async {
                 switch result {
                 case .success(let profile):
                     if profile.isEmpty {
                         self.StatusLabel.text = "User Not Found"
                         self.StatusLabel.isHidden = false
                     } else {
                         let vc = UIStoryboard(name: "Authenticated", bundle: nil).instantiateViewController(withIdentifier: "ViewProfileViewController") as! ViewProfileViewController
                         vc.userId = profile[0].userId
                         vc.isNavigated = true // Enable swipe gesture for dismissal
                         vc.modalPresentationStyle = .fullScreen
                         self.present(vc, animated: true, completion: nil)
                     }
                 case .failure(let error):
                     print("Error fetching \(error.localizedDescription)")
                     self.StatusLabel.text = "Error fetching user"
                     self.StatusLabel.isHidden = false
                 }
             }
         }
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
