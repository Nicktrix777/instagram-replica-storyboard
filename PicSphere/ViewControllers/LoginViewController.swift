//
//  LoginViewController.swift
//  PicSphere
//
//  Created by Nikhil Kaushik on 19/07/24.
//

import UIKit

class LoginViewController: UIViewController {

    // MARK: - IB Outlets
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var registerInsteadButton: UILabel!
    
    // ViewModel Instance
    let viewModel = LoginViewModel()
    
    // Loader View
    private let loaderView: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView(style: .large)
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.backgroundColor = UIColor(white: 0, alpha: 0.5) // Semi-transparent background
        loader.layer.cornerRadius = 10
        loader.clipsToBounds = true
        return loader
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLoader()
    }
    
    func setupUI() {
        let registerTapGesture = UITapGestureRecognizer(target: self, action: #selector(registerTapped(_:)))
        registerInsteadButton.isUserInteractionEnabled = true
        registerInsteadButton.addGestureRecognizer(registerTapGesture)
        passwordTF.isSecureTextEntry = true
        navigationItem.hidesBackButton = true
    }
    
    func setupLoader() {
        view.addSubview(loaderView)
        // Center loader in the view
        NSLayoutConstraint.activate([
            loaderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loaderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loaderView.widthAnchor.constraint(equalToConstant: 100),
            loaderView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    // MARK: - IB Actions
    @objc func registerTapped(_ sender: UITapGestureRecognizer) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        guard let email = emailTF.text, !email.isEmpty else {
            showAlert(message: "Please enter an email address.")
            return
        }
        guard let password = passwordTF.text, !password.isEmpty else {
            showAlert(message: "Please enter a password.")
            return
        }
        
        let request = LoginRequest(email: email, password: password)
        
        // Show loader
        showLoader()
        
        viewModel.login(request: request) { [weak self] result in
            // Hide loader
            self?.hideLoader()
            
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.showAlert(message: "Login successful!") {
                        self?.navigateToAuthenticatedScreen()
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(message: "Login failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showLoader() {
        loaderView.startAnimating()
        loaderView.isHidden = false
    }
    
    private func hideLoader() {
        loaderView.stopAnimating()
        loaderView.isHidden = true
    }
    
    private func navigateToAuthenticatedScreen() {
        let storyboard = UIStoryboard(name: "Authenticated", bundle: nil)
        guard let rootController = storyboard.instantiateViewController(withIdentifier: "AuthenticatedTabBarController") as? UITabBarController else {
            fatalError("Failed to instantiate tab bar controller from 'Authenticated' storyboard")
        }
        NavigationHelper.changeRootViewController(vc: rootController)
    }
    
    private func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true, completion: nil)
    }
}


