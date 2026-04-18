import SwiftUI
import Combine
import KakaoSDKAuth
import KakaoSDKUser

@MainActor
class LoginViewModel: ObservableObject {
    
    // MARK: - State
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var toastMessage: String?
    @Published var showToast = false
    
    // MARK: - Routing Callbacks
    var onLoginSuccess: () -> Void = {}
    var onShowOnboarding: (String, String, String, String, String) -> Void = { _, _, _, _, _ in }
    var onShowMembership: () -> Void = {}
    var onShowFindAccount: () -> Void = {}
    
    private let service: AppService
    private var cancellables = Set<AnyCancellable>()
    
    init(service: AppService) {
        self.service = service
        self.email = "sel1@gmail.com"  // Pre-fill for testing
        self.password = "1234"         // Pre-fill for testing
    }
    
    // MARK: - Manual Login
    func login() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPwd = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty { showToast(message: "이메일을 입력해 주세요."); return }
        if !isValidEmail(trimmedEmail) { showToast(message: "이메일 형식이 올바르지 않습니다."); return }
        if trimmedPwd.isEmpty { showToast(message: "비밀번호를 입력해 주세요."); return }
        
        isLoading = true
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let regId = LoginInfoUtil.getUserNo()
        
        if let response = await service.login(
            email: trimmedEmail,
            password: trimmedPwd,
            loginCd: "PWD",
            regId: regId,
            appVersion: appVersion,
            providerUserId: ""
        ) {
            isLoading = false
            switch response.resultCode {
            case StaticDataInfo.RESULT_CODE_200:
                LoginInfoUtil.saveLoginInfo(response, email: trimmedEmail, password: trimmedPwd)
                if let token = response.token {
                    TokenUtil.saveToken(token)
                }
                PushTokenUtil.ensureTokenRegistered()
                onLoginSuccess()
                
            case StaticDataInfo.RESULT_NO_USER, StaticDataInfo.RESULT_NO_DATA:
                showToast(message: "가입된 이메일을 찾을 수 없습니다.")
            case StaticDataInfo.RESULT_MEMBER_CODE_ERR:
                showToast(message: "회원 유형이 올바르지 않습니다.")
            case StaticDataInfo.RESULT_PWD_ERR:
                showToast(message: "비밀번호가 일치하지 않습니다.")
            default:
                showToast(message: "서버 통신 중 오류가 발생했습니다. (code: \(response.resultCode))")
            }
        } else {
            isLoading = false
            showToast(message: "서버 통신 중 오류가 발생했습니다.")
        }
    }
    
    // MARK: - Kakao Login
    func loginWithKakao() {
        isLoading = true
        
        let callback: (OAuthToken?, Error?) -> Void = { [weak self] token, error in
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
                    self.isLoading = false
                    if self.isKakaoCancelled(error) {
                        self.showToast(message: "로그인이 취소되었습니다.")
                    } else {
                        // fallback to account if talk login fails
                        self.loginWithKakaoAccount()
                    }
                }
                return
            }
            
            if let token = token {
                Task { @MainActor in
                    await self.fetchKakaoUserAndAuth(token: token)
                }
            } else {
                Task { @MainActor in
                    self.isLoading = false
                    self.showToast(message: "카카오 토큰이 없습니다.")
                }
            }
        }
        
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk(completion: callback)
        } else {
            loginWithKakaoAccount()
        }
    }
    
    private func loginWithKakaoAccount() {
        isLoading = true
        UserApi.shared.loginWithKakaoAccount { [weak self] token, error in
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
                    self.isLoading = false
                    self.showToast(message: "카카오 계정 로그인 실패: \(error.localizedDescription)")
                }
                return
            }
            
            if let token = token {
                Task { @MainActor in
                    await self.fetchKakaoUserAndAuth(token: token)
                }
            } else {
                Task { @MainActor in
                    self.isLoading = false
                    self.showToast(message: "카카오 토큰이 없습니다.")
                }
            }
        }
    }
    
    private func fetchKakaoUserAndAuth(token: OAuthToken) async {
        isLoading = true
        
        // Use withCheckedContinuation to bridge callback to async/await
        let userResult: Result<User, Error> = await withCheckedContinuation { continuation in
            UserApi.shared.me { user, error in
                if let error = error {
                    continuation.resume(returning: .failure(error))
                } else if let user = user {
                    continuation.resume(returning: .success(user))
                }
            }
        }
        
        switch userResult {
        case .success(let user):
            guard let id = user.id else {
                isLoading = false
                showToast(message: "카카오 사용자 정보가 없습니다.")
                return
            }
            
            let kakaoUserId = String(id)
            let nickname = user.kakaoAccount?.profile?.nickname ?? ""
            let email = user.kakaoAccount?.email ?? ""
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
            
            if let auth = await service.authSocial(req) {
                isLoading = false
                if auth.resultCode == StaticDataInfo.RESULT_CODE_200,
                   let jwt = auth.token, !jwt.isEmpty {
                    LoginInfoUtil.saveLoginInfo(auth, email: auth.loginId, password: auth.loginPwd)
                    TokenUtil.saveToken(jwt)
                    PushTokenUtil.ensureTokenRegistered()
                    onLoginSuccess()
                    return
                }
                
                if auth.resultCode == 604 {
                    onShowOnboarding("KAKAO", kakaoUserId, nickname, email, profileUrl)
                    return
                }
                
                showToast(message: "소셜 로그인 실패 (code: \(auth.resultCode))")
            } else {
                isLoading = false
                showToast(message: "소셜 로그인 응답이 없습니다.")
            }
            
        case .failure(let error):
            isLoading = false
            showToast(message: "카카오 사용자 조회 실패: \(error.localizedDescription)")
        }
    }
    
    private func isKakaoCancelled(_ error: Error) -> Bool {
        let msg = (error as NSError).localizedDescription.lowercased()
        return msg.contains("cancel")
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
    
    private func showToast(message: String) {
        toastMessage = message
        showToast = true
    }
}
