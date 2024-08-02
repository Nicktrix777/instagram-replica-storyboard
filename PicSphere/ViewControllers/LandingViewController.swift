//
//  LandingViewController.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 19/07/24.
//

import UIKit

class LandingViewController: UIViewController {

    // MARK: - IB Outlets
    @IBOutlet weak var usernameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var confirmPWTF: UITextField!
    @IBOutlet weak var loginInsteadButton: UILabel!
    
    // ViewModel instance
    var viewModel = LandingViewModel()
    
    // Loader instance
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActivityIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkAuthStatus()
    }
    
    func setupUI() {
        passwordTF.isSecureTextEntry = true
        confirmPWTF.isSecureTextEntry = true
        let loginTapGesture = UITapGestureRecognizer(target: self, action: #selector(loginTapped(_:)))
        loginInsteadButton.isUserInteractionEnabled = true
        loginInsteadButton.addGestureRecognizer(loginTapGesture)
    }
    
    func setupActivityIndicator() {
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
    }
    
    func checkAuthStatus() {
        activityIndicator.startAnimating() // Start the loader
        viewModel.restoreSession { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating() // Stop the loader
                switch result {
                case .success:
                    self?.navigateToAuthenticatedScreen()
                case .failure(let error):
                    print("Error restoring session: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @IBAction func registerButtonTapped(_ sender: UIButton) {
        guard let username = usernameTF.text, !username.isEmpty else {
            showAlert(message: "Please enter a username.")
            return
        }
        guard let email = emailTF.text, !email.isEmpty else {
            showAlert(message: "Please enter an email address.")
            return
        }
        guard let password = passwordTF.text, !password.isEmpty else {
            showAlert(message: "Please enter a password.")
            return
        }
        guard let confirmPassword = confirmPWTF.text, !confirmPassword.isEmpty else {
            showAlert(message: "Please confirm your password.")
            return
        }
        guard password == confirmPassword else {
            showAlert(message: "Passwords do not match.")
            return
        }
        
        let request = RegisterRequest(username: username, email: email, password: password, confirmPassword: confirmPassword)
        
        activityIndicator.startAnimating() // Start the loader
        viewModel.register(request: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating() // Stop the loader
                switch result {
                case .success:
                    self?.showAlert(message: "Registration successful!")
                    self?.navigateToAuthenticatedScreen()
                case .failure(let error):
                    self?.showAlert(message: "Registration failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc func loginTapped(_ sender: UITapGestureRecognizer) {
        let loginVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        self.navigationController?.pushViewController(loginVC, animated: true)
    }
    
    func navigateToAuthenticatedScreen() {
        let storyboard = UIStoryboard(name: "Authenticated", bundle: nil)
        guard let rootController = storyboard.instantiateViewController(withIdentifier: "AuthenticatedTabBarController") as? UITabBarController else {
            fatalError("Failed to instantiate tab bar controller from 'Authenticated' storyboard")
        }
        NavigationHelper.changeRootViewController(vc: rootController)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
