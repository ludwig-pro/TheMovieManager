 //
 //  LoginViewController.swift
 //  TheMovieManager
 //
 //  Created by Owen LaRosa on 8/13/18.
 //  Copyright © 2018 Udacity. All rights reserved.
 //
 
 import UIKit
 
 class LoginViewController: UIViewController {
  
  @IBOutlet weak var loader: UIActivityIndicatorView!
  @IBOutlet weak var emailTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var loginViaWebsiteButton: UIButton!
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    emailTextField.text = ""
    passwordTextField.text = ""
    
  }
  
  @IBAction func loginTapped(_ sender: UIButton) {
    setLoggingIn(true)
    TMDBClient.getRequestToken(completion: getToken)
  }
  
  @IBAction func loginViaWebsiteTapped() {
    TMDBClient.getRequestToken { (success, error) in
      if success {
        UIApplication.shared.open(TMDBClient.Endpoints.webAuth.url, options: [:], completionHandler: nil )
      } else {
        self.showLoginFailure(message: error?.localizedDescription ?? "")
      }
      
    }
  }
  
  func getToken(success: Bool, error: Error?) {
    if success {
      TMDBClient.login(login: self.emailTextField.text ?? "", password: self.passwordTextField.text ?? "", completion: self.handleLoginResponse(success:error:))
    } else {
      setLoggingIn(false)
      showLoginFailure(message: error?.localizedDescription ?? "")
    }
  }
  
  func handleLoginResponse(success: Bool, error: Error?){
    if success {
      TMDBClient.session(completion: handleSession)
    } else {
      setLoggingIn(false)
      showLoginFailure(message: error?.localizedDescription ?? "")

    }
  }
  
  func handleSession(success: Bool, error: Error?) {
    setLoggingIn(false)
    if success {
      self.performSegue(withIdentifier: "completeLogin", sender: nil)
    } else {
      showLoginFailure(message: error?.localizedDescription ?? "")
    }

  }
  
  func setLoggingIn(_ loggingIn: Bool) {
    if loggingIn {
      loader.startAnimating()
    } else {
      loader.stopAnimating()
    }
    emailTextField.isEnabled = !loggingIn
    passwordTextField.isEnabled = !loggingIn
    loginButton.isEnabled = !loggingIn
    loginViaWebsiteButton.isEnabled = !loggingIn
  }
  
  func showLoginFailure(message: String) {
    let alertVC = UIAlertController(title: "Login Failed", message: message, preferredStyle: .alert)
    alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    show(alertVC, sender: nil)
  }
  
 }
