//
//  LoginViewController.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import UIKit
import KakaoSDKAuth
import KakaoSDKUser

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
    @IBOutlet weak var kakaoLogOutButton: UIButton!

    @IBOutlet weak var membershipButton: UIButton!
    @IBOutlet weak var findIdPwdButton: UIButton!

    @IBOutlet weak var progressOverlayView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var selectedUserType: String = Constants.ROLE_SELL
    var pendingDeepLink: PushDeepLink?
    var coordinator: AppCoordinator?
    private let appService = AppServiceProvider.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        enableDismissKeyboardOnTap()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // ✅ 로그인 화면에서는 메뉴 버튼 자체 없음
        navigationItem.leftBarButtonItem = nil

        // ✅ 스와이프/엣지 제스처로 메뉴 열리는 것도 차단
        navigationController?.view.gestureRecognizers?.forEach { $0.isEnabled = false }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // ✅ 로그인 화면을 나가면 다시 제스처 복구(다른 화면에서 메뉴 사용 가능)
        navigationController?.view.gestureRecognizers?.forEach { $0.isEnabled = true }
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

        // 카카오 로그인해제 버튼
        kakaoLogOutButton.translatesAutoresizingMaskIntoConstraints = false
        kakaoLogOutButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        kakaoLogOutButton.setFont(size: 20, weight: .bold)

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

    @IBAction func kakaoLoginButtonTapped(_ sender: UIButton) {
        startKakaoLogin()
    }

    @IBAction func kakaoLogOutButtonTapped(_ sender: UIButton) {
        unlinkKakaoForTest()
    }

    @IBAction func googleLoginButtonTapped(_ sender: UIButton) {
    }

    func unlinkKakaoForTest(completion: (() -> Void)? = nil) {
        UserApi.shared.unlink { [weak self] error in
            guard let self else { return }

            if let error = error {
                print("KAKAO unlink 실패:", error)
                DispatchQueue.main.async {
                    self.presentKakaoAlert(title: "연결 해제 실패", message: "잠시 후 다시 시도해주세요.")
                    completion?()
                }
                return
            }

            print("KAKAO unlink 성공 (연결 해제 완료)")

            // ✅ 카카오 세션 정리
            UserApi.shared.logout { logoutError in
                if let logoutError = logoutError {
                    print("KAKAO logout 실패:", logoutError)
                } else {
                    print("KAKAO logout 성공")
                }

                // ✅ 우리 앱 저장 로그인/토큰 삭제 (핵심)
                LoginInfoUtil.clearLoginInfo()
                TokenUtil.clearToken()

                DispatchQueue.main.async {
                    self.presentKakaoAlert(
                        title: "카카오 연결 해제 완료",
                        message: "저장된 로그인 정보를 삭제했습니다.\n다른 계정으로 다시 로그인하세요."
                    )
                    completion?()
                }
            }
        }
    }

    private func presentKakaoAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        self.present(alert, animated: true)
    }
    
    @IBAction func membershipButtonTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Main", bundle: nil)

        guard let vc = sb.instantiateViewController(
            withIdentifier: "TermsAgreeVC"
        ) as? TermsAgreeViewController else {
            assertionFailure("TermsAgreeVC not found in storyboard")
            return
        }
        print("membershipButtonTapped coordinator is nil? ->", coordinator == nil)
        vc.coordinator = self.coordinator
       navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func findIdPwdButtonTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(
            withIdentifier: "FindAccountVC"
        ) as? FindAccountViewController else {
            assertionFailure("FindAccountVC not found in storyboard")
            return
        }
        // ✅ 서비스 주입 (네 프로젝트 방식에 맞게)
        vc.service = appService   // ← 실제 사용하는 서비스로 교체
        // ✅ 네비게이션으로 이동
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
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
                print("coordinator is nil? ->", coordinator == nil)
                
                coordinator?.showIntro(launchDeepLink: pendingDeepLink, animated: true)
                
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
    // MARK: - Kakao Login (Android flow same)

    private func startKakaoLogin() {
        showLoading(true)

        let callback: (OAuthToken?, Error?) -> Void = { [weak self] token, error in
            guard let self = self else { return }
            self.showLoading(false)

            if let error = error {
                // 취소면 메시지만
                if self.isKakaoCancelled(error) {
                    self.showAlert(message: "로그인이 취소되었습니다.")
                    return
                }
                // 그 외 에러면 계정 로그인 폴백
                self.loginWithKakaoAccount()
                return
            }

            guard let token = token else {
                self.showAlert(message: "카카오 토큰이 없습니다.")
                return
            }

            self.fetchKakaoUserAndGo(token: token)
        }

        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk(completion: callback)
        } else {
            loginWithKakaoAccount()
        }
    }

    private func loginWithKakaoAccount() {
        showLoading(true)
        UserApi.shared.loginWithKakaoAccount { [weak self] token, error in
            guard let self = self else { return }
            self.showLoading(false)

            if let error = error {
                self.showAlert(message: "카카오 계정 로그인 실패: \(error.localizedDescription)")
                return
            }

            guard let token = token else {
                self.showAlert(message: "카카오 토큰이 없습니다.")
                return
            }

            self.fetchKakaoUserAndGo(token: token)
        }
    }

    // Android: fetchKakaoUserAndGo(token) + authSocial + (200/604) 분기
    private func fetchKakaoUserAndGo(token: OAuthToken) {
        startLoading()

        UserApi.shared.me { [weak self] user, error in
            guard let self = self else { return }

            if let error = error {
                self.stopLoading()
                self.showAlert(message: "카카오 사용자 조회 실패: \(error.localizedDescription)")
                return
            }

            guard let user = user, let id = user.id else {
                self.stopLoading()
                self.showAlert(message: "카카오 사용자 정보가 없습니다.")
                return
            }

            let kakaoUserId = String(id)
            let nickname = user.kakaoAccount?.profile?.nickname ?? ""
            let email = user.kakaoAccount?.email ?? "" // 없을 수도 있음
            let profileUrl = user.kakaoAccount?.profile?.profileImageUrl?.absoluteString ?? ""

            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            let deviceId = UIDevice.current.identifierForVendor?.uuidString

            let req = SocialAuthRequest(
                provider: "KAKAO",
                providerUserId: kakaoUserId,
                accessToken: token.accessToken,
                idToken: nil,
                deviceId: deviceId,
                appVersion: appVersion
            )

            Task { [weak self] in
                guard let self = self else { return }
                defer { self.stopLoading() }

                do {
                    let auth = try await self.appService.authSocial(req)
                    guard let auth = auth else {
                        self.showAlert(message: "로그인 응답이 없습니다.")
                        return
                    }
                    // ✅ 성공 (Android: resultCode==200 && token not blank)
                    if auth.resultCode == StaticDataInfo.RESULT_CODE_200,
                       let jwt = auth.token, !jwt.isEmpty {

                        // Android도 TODO였으니 iOS도 일단 주석
                        // self.service.saveJwt(jwt)

                        // ✅ Android: LoginInfoUtil.saveLoginInfo(...) 동일 역할
                        LoginInfoUtil.saveLoginInfo(
                            email: auth.loginId ?? "",                  // 서버가 loginId 주면 그걸 우선
                            loginNo: auth.loginIdx ?? "",
                            password: auth.loginPwd ?? "",              // 소셜이면 보통 ""
                            memberCode: auth.memberCode ?? "",
                            loginNm: auth.loginNm ?? "",
                            loginCd: auth.loginCd ?? "KAKAO",
                            loginSocialId: auth.loginSocialId ?? ""
                        )

                        // ✅ Android: IntroActivity로 이동
                        self.coordinator?.showIntro(
                            launchDeepLink: self.pendingDeepLink,
                            animated: true
                        )
                        return
                    }

                    // ✅ 온보딩 (Android: 604)
                    if auth.resultCode == 604 {
                        self.openOnboarding(
                            provider: "KAKAO",
                            providerUserId: kakaoUserId,
                            nickname: nickname,
                            email: email,
                            profileUrl: profileUrl
                        )
                        return
                    }

                    self.showAlert(message: "소셜 로그인 실패(code=\(auth.resultCode))")

                } catch {
                    self.showAlert(message: "서버 통신 오류: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Onboarding 이동 (스토리보드 ID 맞춰서 사용)
    private func openOnboarding(
        provider: String,
        providerUserId: String,
        nickname: String,
        email: String,
        profileUrl: String
    ) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "OnboardingVC") as? OnboardingViewController else {
            showAlert(message: "OnboardingVC not found")
            return
        }

        // ✅ 필수 주입
        vc.service = appService
        vc.coordinator = coordinator
        vc.pendingDeepLink = pendingDeepLink

        // ✅ 소셜 정보 전달
        vc.provider = provider
        vc.providerUserId = providerUserId
        vc.presetNickname = nickname
        vc.presetEmail = email
        // profileUrl은 필요하면 나중에 사용 (지금은 OK)

        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }

    // MARK: - Cancel 판단 (간단 버전)
    private func isKakaoCancelled(_ error: Error) -> Bool {
        let msg = (error as NSError).localizedDescription.lowercased()
        return msg.contains("cancel")
    }

}
