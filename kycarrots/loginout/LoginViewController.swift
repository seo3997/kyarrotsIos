//
//  LoginViewController.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import UIKit

class LoginViewController: UIViewController {
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var passwordContainerView: UIView!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var kakaoLoginButton: UIButton!
    @IBOutlet weak var googleLoginButton: UIButton!

    @IBOutlet weak var membershipButton: UIButton!
    @IBOutlet weak var findIdPwdButton: UIButton!

    @IBOutlet weak var progressOverlayView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        // 배경은 스토리보드에서 설정할 거라 여기선 패스해도 됨
        backgroundImageView.contentMode = .scaleAspectFill
            backgroundImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.deactivate(backgroundImageView.constraints) // 혹시 남은 거 있으면

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // placeholder 색을 흰색으로 (안드로이드 hint 색과 유사)
        if let emailPlaceholder = emailTextField.placeholder {
            emailTextField.attributedPlaceholder = NSAttributedString(
                string: emailPlaceholder,
                attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.7)]
            )
        }
        if let pwdPlaceholder = passwordTextField.placeholder {
            passwordTextField.attributedPlaceholder = NSAttributedString(
                string: pwdPlaceholder,
                attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.7)]
            )
        }
        emailTextField.borderStyle = .none
        passwordTextField.borderStyle = .none

        //emailTextField.textColor = .white
        //passwordTextField.textColor = .white
        
        setupButtonHeights()
        contentStackView.setCustomSpacing(70, after: passwordContainerView)
        
        // 카카오 버튼 스타일
        /*
        kakaoLoginButton.backgroundColor = UIColor(red: 0xFE/255.0, green: 0xE5/255.0, blue: 0x00/255.0, alpha: 1)
        kakaoLoginButton.setTitleColor(UIColor(red: 0x19/255.0, green: 0x19/255.0, blue: 0x19/255.0, alpha: 1), for: .normal)

        // Google 버튼은 기본적으로 숨김 (android:visibility="gone")
        googleLoginButton.isHidden = true
        */
        
        // 프로그레스 오버레이 숨김
        progressOverlayView.isHidden = true
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .large          // 더 크게
        activityIndicator.color = .white          // 흰색으로 또렷하게
        activityIndicator.hidesWhenStopped = true
    }
    
    private func setupButtonHeights() {
        // 로그인 버튼
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true  // 원하는 크기
        loginButton.setFont(size: 20, weight: .bold)
        
        // 카카오 로그인 버튼
        kakaoLoginButton.translatesAutoresizingMaskIntoConstraints = false
        kakaoLoginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        kakaoLoginButton.setFont(size: 20, weight: .bold)

        // 구글 로그인 버튼 (이건 hidden 일 때도 height 필요)
        googleLoginButton.translatesAutoresizingMaskIntoConstraints = false
        googleLoginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        googleLoginButton.setFont(size: 20, weight: .bold)

        // 회원가입 / 아이디찾기 버튼 (얇아도 괜찮음)
        membershipButton.translatesAutoresizingMaskIntoConstraints = false
        membershipButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        membershipButton.setFont(size: 20, weight: .bold)

        findIdPwdButton.translatesAutoresizingMaskIntoConstraints = false
        findIdPwdButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        findIdPwdButton.setFont(size: 20, weight: .bold)
    }
    
    func showLoading(_ show: Bool) {
        progressOverlayView.isHidden = !show
        if show {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        showLoading(true)
        // 로그인 API 호출 예정
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let dashboardVC = storyboard.instantiateViewController(withIdentifier: "DashboardVC")
        switchRoot(to: dashboardVC)
    }

    @IBAction func kakaoLoginButtonTapped(_ sender: UIButton) { }

    @IBAction func googleLoginButtonTapped(_ sender: UIButton) { }

    @IBAction func membershipButtonTapped(_ sender: UIButton) { }

    @IBAction func findIdPwdButtonTapped(_ sender: UIButton) { }
}
