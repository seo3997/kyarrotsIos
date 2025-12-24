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

    var selectedUserType: String = Constants.ROLE_SELL
    
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
    
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern,
                           options: [.regularExpression, .caseInsensitive]) != nil
    }
    
    func showLoading(_ show: Bool) {
        progressOverlayView.isHidden = !show
        if show {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    private func startLoading() {
        progressOverlayView.isHidden = false
        activityIndicator.startAnimating()
    }

    private func stopLoading() {
        activityIndicator.stopAnimating()
        progressOverlayView.isHidden = true
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        //showLoading(true)
        chkLoginCondition()
        // 로그인 API 호출 예정
        /*
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let dashboardVC = storyboard.instantiateViewController(withIdentifier: "DashboardVC")
        switchRoot(to: dashboardVC)
        */
    }

    @IBAction func kakaoLoginButtonTapped(_ sender: UIButton) { }

    @IBAction func googleLoginButtonTapped(_ sender: UIButton) { }

    @IBAction func membershipButtonTapped(_ sender: UIButton) { }

    @IBAction func findIdPwdButtonTapped(_ sender: UIButton) { }
    
    
    private func chkLoginCondition() {
        let email = (emailTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let pwd   = (passwordTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let memberCode = selectedUserType      // ROLE_SELL / ROLE_PUB / ROLE_PROJ

        // 1) 이메일 공백 체크
        if email.isEmpty {
            showAlert(message: "이메일을 입력해 주세요.")   // str_input_id_err
            return
        }

        // 2) 이메일 형식 체크
        if !isValidEmail(email) {
            showAlert(message: "이메일 형식이 올바르지 않습니다.")
            return
        }

        // 3) 비밀번호 공백 체크
        if pwd.isEmpty {
            showAlert(message: "비밀번호를 입력해 주세요.") // str_input_pwd_err
            return
        }

        // 4) 직거래앱 + 센터 로그인 방지
        if memberCode == Constants.ROLE_PROJ && Constants.SYSTEM_TYPE == 1 {
            showAlert(message: "직거래앱은 센터로 로그인 할 수 없습니다.")
            return
        }

        // 5) 서버 로그인 호출
        startLoading()

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let appService = AppServiceProvider.shared

        let regId = LoginInfoUtil.getUserNo()
        Task { [weak self] in
            guard let self = self else { return }
            defer { self.stopLoading() }

            //throw 안 하는 async 함수이므로 try X, 그냥 await O
            guard let response = await appService.login(
                email: email,
                password: pwd,
                loginCd: "PWD",
                regId: regId,
                appVersion: appVersion,
                providerUserId: ""
            ) else {
                // repo.login() 이 실패했거나 응답이 nil 이면 여기로
                self.showAlert(message: "서버 통신 중 오류가 발생했습니다.")
                return
            }

            // 여기서부터는 response 가 non-optional
            let resultCode = response.resultCode   // ← LoginResponse 안에 resultCode(Int) 있다고 가정

            switch resultCode {
            case StaticDataInfo.RESULT_CODE_200:
                print("로그인 성공: resultCode=\(resultCode)")

                // 로그인 정보 저장 (필드 이름은 실제 모델에 맞게 수정)
                LoginInfoUtil.saveLoginInfo(
                    email: email,
                    loginNo: response.loginIdx ?? "",
                    password: pwd,
                    memberCode: response.memberCode ?? "",
                    loginNm: response.loginNm ?? "",
                    loginCd: "PWD",
                    loginSocialId: ""
                )

                if let token = response.token {
                    TokenUtil.saveToken(token)
                }

                let userRole = LoginInfoUtil.getMemberCode()

                if userRole == "ROLE_SELL" || userRole == "ROLE_PROJ" {
                    // 판매자 또는 도매업자인 경우: 기존 DashboardVC로 이동
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let dashboardVC = storyboard.instantiateViewController(withIdentifier: "DashboardVC")
                    switchRoot(to: dashboardVC)
                } else {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let mainTabVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarVC")
                    switchRoot(to: mainTabVC)
                }

            case StaticDataInfo.RESULT_NO_USER,
                 StaticDataInfo.RESULT_NO_DATA:
                self.showAlert(message: "가입된 이메일을 찾을 수 없습니다.")

            case StaticDataInfo.RESULT_MEMBER_CODE_ERR:
                self.showAlert(message: "회원 유형이 올바르지 않습니다.")

            case StaticDataInfo.RESULT_NO_SOCAIL_DATA:
                self.showAlert(message: "소셜 계정 정보가 없습니다.")

            case StaticDataInfo.RESULT_PWD_ERR:
                self.showAlert(message: "비밀번호가 일치하지 않습니다.")

            case StaticDataInfo.RESULT_CODE_ERR:
                fallthrough
            default:
                self.showAlert(message: "서버 통신 중 오류가 발생했습니다.")
            }
        }
        
    }

}
