//
//  ProfileViewController.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 19/07/24.
//

import UIKit
import Kingfisher

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var usernameTF: UITextField!
    @IBOutlet weak var editUsername: UIImageView!
    @IBOutlet weak var doneEditingName: UIButton!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var doneEditingPassword: UIButton!
    @IBOutlet weak var editPasswordTF: UITextField!
    @IBOutlet weak var editPassword: UIImageView!
    @IBOutlet weak var bioTF: UITextView!
    @IBOutlet weak var editBioButton: UIButton!

    let profileViewModel = ProfileViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        populateUserInfo()
    }

    func setupUI() {
        self.navigationItem.hidesBackButton = true
        doneEditingName.isHidden = true
        usernameTF.isEnabled = false
        emailTF.isEnabled = false
        editPasswordTF.isEnabled = false
        editPasswordTF.isSecureTextEntry = true
        doneEditingPassword.isHidden = true
        profilePicture.layer.cornerRadius = profilePicture.frame.height / 2
        profilePicture.layer.masksToBounds = true
        bioTF.isEditable = false
        setupGestures()
    }

    func setupGestures() {
        setupTapGesture(for: editUsername, action: #selector(handleEditUsernameGesture(_:)))
        setupTapGesture(for: profilePicture, action: #selector(handleProfilePictureGesture(_:)))
        setupTapGesture(for: editPassword, action: #selector(handleEditPasswordGesture(_:)))
        setupTapGesture(for: editBioButton, action: #selector(handleEditBioGesture(_:)))
    }

    func setupTapGesture(for view: UIView, action: Selector) {
        let gesture = UITapGestureRecognizer(target: self, action: action)
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(gesture)
    }

    @objc func handleEditUsernameGesture(_ sender: UITapGestureRecognizer) {
        usernameTF.isEnabled = true
        doneEditingName.isHidden = false
    }

    @objc func handleEditPasswordGesture(_ sender: UITapGestureRecognizer) {
        editPasswordTF.isEnabled = true
        doneEditingPassword.isHidden = false
    }

    @objc func handleProfilePictureGesture(_ sender: UITapGestureRecognizer) {
        showImagePicker(for: .profilePicture) { [weak self] imageURL in
            guard let self = self, let imagePath = imageURL?.path else { return }
            self.profileViewModel.uploadOrReplaceProfileImage(imagePath: imagePath) { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.profilePicture.image = UIImage(contentsOfFile: imagePath)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        print("Profile image upload failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    @objc func handleEditBioGesture(_ sender: UITapGestureRecognizer) {
        if editBioButton.titleLabel?.text == "Edit Bio" {
            bioTF.isEditable = true
            editBioButton.setTitle("Done", for: .normal)
        } else {
            guard let bio = bioTF.text else { return }
            profileViewModel.editBio(bio: bio) { [weak self] result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self?.bioTF.isEditable = false
                        self?.editBioButton.setTitle("Edit Bio", for: .normal)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        print("Failed to edit bio: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func showImagePicker(for actionType: ImagePickerActionType, completion: @escaping (URL?) -> Void) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true

        let alert = UIAlertController(title: "Choose Image Source", message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                imagePicker.sourceType = .camera
                self.present(imagePicker, animated: true, completion: nil)
            }))
        }

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
                imagePicker.sourceType = .photoLibrary
                self.present(imagePicker, animated: true, completion: nil)
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)

        self.imagePickerCompletion = completion
    }

    var imagePickerCompletion: ((URL?) -> Void)?

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let imageURL = info[.imageURL] as? URL {
            imagePickerCompletion?(imageURL)
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func populateUserInfo() {
        guard let profile = UserState.shared.profile else { return }
        usernameTF.text = profile.username
        emailTF.text = profile.email
        bioTF.text = profile.bio
        
        if let profileImageURL = profile.profilePictureURL, let url = URL(string: profileImageURL) {
            DispatchQueue.main.async {
                self.profilePicture.kf.setImage(with: url)
            }
        }
        else {
            self.profilePicture.image = UIImage(systemName: "person.fill")
        }
    }

    @IBAction func logoutPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Confirm Logout", message: "Are you sure you want to log out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { [weak self] _ in
            self?.profileViewModel.logout { result in
                switch result {
                case .success:
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let landingNavController = storyboard.instantiateViewController(withIdentifier: "LandingNavController") as? UINavigationController {
                        NavigationHelper.changeRootViewController(vc: landingNavController)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        print("Logout failed: \(error.localizedDescription)")
                    }
                }
            }
        }))
        present(alert, animated: true, completion: nil)
    }

    @IBAction func doneEditingUsername(_ sender: Any) {
        guard let username = usernameTF.text else { return }
        profileViewModel.editUsername(username: username) { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.usernameTF.isEnabled = false
                    self?.doneEditingName.isHidden = true
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    print("Failed to edit username: \(error.localizedDescription)")
                }
            }
        }
    }

    @IBAction func doneEditingPassword(_ sender: Any) {
        guard let password = editPasswordTF.text else { return }
        profileViewModel.editPassword(password: password) { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.editPasswordTF.isEnabled = false
                    self?.doneEditingPassword.isHidden = true
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    print("Failed to edit password: \(error.localizedDescription)")
                }
            }
        }
    }

    @IBAction func addNewStoryPressed(_ sender: Any) {
        showImagePicker(for: .story) { [weak self] imageURL in
            guard let self = self, let imagePath = imageURL?.path else { return }
            self.profileViewModel.uploadStoryImage(imagePath: imagePath) { result in
                switch result {
                case .success:
                    print("Story upload successful")
                case .failure(let error):
                    print("Story upload failed: \(error.localizedDescription)")
                }
            }
        }
    }

    @IBAction func addNewPostPressed(_ sender: Any) {
        showImagePicker(for: .post) { [weak self] imageURL in
            guard let self = self, let imagePath = imageURL?.path else { return }
            self.profileViewModel.uploadPostImage(imagePath: imagePath) { result in
                switch result {
                case .success:
                    print("Post upload successful")
                case .failure(let error):
                    print("Post upload failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// Enum to specify image picker action types
enum ImagePickerActionType {
    case profilePicture
    case story
    case post
}
