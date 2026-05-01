import SwiftUI
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    
    // MARK: - Injected Properties
    let provider: String
    let providerUserId: String
    let presetEmail: String
    let presetNickname: String
    
    private let service: AppService
    
    // MARK: - State
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var passwordConfirm = ""
    @Published var birth = ""
    @Published var phoneFirst = "010"
    @Published var phoneMid = ""
    @Published var phoneLast = ""
    @Published var gender = 0 // 0: None, 1: Male, 2: Female
    
    @Published var branchList: [BranchInfoVo] = []
    @Published var selectedBranch: BranchInfoVo?
    
    @Published var isEmailChecked = false
    @Published var isFormVisible = false
    @Published var isLoading = false
    @Published var toastMessage: String?
    @Published var showToast = false
    @Published var emailStatusMessage = ""
    @Published var lastCheckedEmail: String? = nil
    
    // MARK: - Navigation Callbacks
    var onShowTerms: (@escaping () -> Void) -> Void = { _ in }
    
    let phoneFirstOptions = ["010", "011", "016", "017", "018", "019"]
    
    private var cancellables = Set<AnyCancellable>()
    
    init(service: AppService, provider: String, providerUserId: String, presetEmail: String, presetNickname: String) {
        self.service = service
        self.provider = provider
        self.providerUserId = providerUserId
        self.presetEmail = presetEmail
        self.presetNickname = presetNickname
        
        self.email = presetEmail
        self.name = presetNickname
        
        // Reset check if email changes
        $email
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self = self else { return }
                // Only reset if it was already checked and the new email is different from the checked one
                if self.isEmailChecked && newValue != self.lastCheckedEmail {
                    self.isEmailChecked = false
                    self.isFormVisible = false
                    self.emailStatusMessage = ""
                }
            }
            .store(in: &cancellables)
            
        // Birth auto-format YYYY-MM-DD
        $birth
            .sink { [weak self] newValue in
                guard let self = self else { return }
                let filtered = newValue.replacingOccurrences(of: "-", with: "").filter { $0.isNumber }
                var out = ""
                for (i, ch) in filtered.prefix(8).enumerated() {
                    if i == 4 || i == 6 { out.append("-") }
                    out.append(ch)
                }
                if out != newValue {
                    DispatchQueue.main.async {
                        self.birth = out
                    }
                }
            }
            .store(in: &cancellables)
            
    }
    
    func loadInitialData() async {
        self.branchList = await service.getBranchList()
    }
    
    func checkEmail(onLinkSuccess: @escaping () -> Void) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 이미 중복 확인이 완료된 상태라면 약관 동의 화면만 다시 노출
        if isEmailChecked && trimmedEmail == lastCheckedEmail {
            onShowTerms { [weak self] in
                self?.isFormVisible = true
            }
            return
        }

        guard isValidEmail(trimmedEmail) else {
            showToast(message: "유효한 이메일을 입력하세요.")
            return
        }
        
        isLoading = true
        if let res = await service.checkEmailDuplicate(email: trimmedEmail) {
            isLoading = false
            if res.result == true {
                // New user
                self.lastCheckedEmail = trimmedEmail
                isEmailChecked = true
                emailStatusMessage = "사용 가능한 이메일입니다."
                
                // Show terms agreement before showing registration form
                onShowTerms { [weak self] in
                    self?.isFormVisible = true
                }
            } else {
                // Existing user -> Link social
                isEmailChecked = false
                emailStatusMessage = "이미 가입된 이메일입니다. 계정 연결을 진행합니다."
                isFormVisible = false
                await linkSocial(email: trimmedEmail, userNo: res.message ?? "", onSuccess: onLinkSuccess)
            }
        } else {
            isLoading = false
            showToast(message: "이메일 중복 확인 실패")
        }
    }
    
    private func linkSocial(email: String, userNo: String, onSuccess: @escaping () -> Void) async {
        let req = LinkSocialRequest(
            userId: email,
            userNo: userNo,
            provider: provider,
            providerUserId: providerUserId
        )
        
        isLoading = true
        if let body = await service.linkSocial(req) {
            isLoading = false
            switch body.resultCode {
            case 200:
                LoginInfoUtil.saveLoginInfo(body, email: email, password: password)
                showToast(message: "소셜계정 링크 성공!!!")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onSuccess()
                }
            case 409: showToast(message: "이미 다른 사용자에 연결된 소셜 계정입니다. (409)")
            case 400: showToast(message: "요청이 올바르지 않습니다. (400)")
            case 601: showToast(message: "사용자를 찾을 수 없습니다. (601)")
            case 500: showToast(message: "서버 오류가 발생했습니다. (500)")
            default:  showToast(message: "연결 실패")
            }
        } else {
            isLoading = false
            showToast(message: "네트워크 오류 발생")
        }
    }
    
    func register(onSuccess: @escaping () -> Void) async {
        if !validate() { return }
        
        let phone = "\(phoneFirst)-\(phoneMid)-\(phoneLast)"
        var user = OpUserVO()
        user.userNm = name
        user.email = email
        user.userId = email
        user.password = password
        user.cttpc = phone
        user.gender = gender
        user.birthDate = birth
        user.areaCode = ""
        user.areaSeCodeS = ""
        user.areaSeCodeD = ""
        user.branchId = selectedBranch?.branchId.map { String($0) } ?? ""
        user.userSttusCode = "10"
        user.memberCode = "ROLE_PUB"
        user.provider = provider
        user.providerUserId = providerUserId
        
        isLoading = true
        if let res = await service.registerUser(user), res.resultCode == 200 {
            LoginInfoUtil.saveLoginInfo(res, email: email, password: password)
            isLoading = false
            showToast(message: "회원가입 성공!")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onSuccess()
            }
        } else {
            isLoading = false
            showToast(message: "회원가입 실패")
        }
    }
    
    private func validate() -> Bool {
        if name.isEmpty { showToast(message: "이름을 입력하세요."); return false }
        if !isValidEmail(email) { showToast(message: "유효한 이메일을 입력하세요."); return false }
        if !isEmailChecked { showToast(message: "이메일 중복 확인을 해주세요."); return false }
        if password.count < 4 { showToast(message: "비밀번호는 최소 4자 이상이어야 합니다."); return false }
        if password != passwordConfirm { showToast(message: "비밀번호가 일치하지 않습니다."); return false }
        if birth.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) == nil {
            showToast(message: "생년월일은 YYYY-MM-DD 형식으로 입력하세요."); return false
        }
        let phone = "\(phoneFirst)-\(phoneMid)-\(phoneLast)"
        if phone.range(of: #"^01[016789]-\d{3,4}-\d{4}$"#, options: .regularExpression) == nil {
            showToast(message: "유효한 전화번호를 입력하세요."); return false
        }
        if gender == 0 { showToast(message: "성별을 선택하세요."); return false }
        if selectedBranch == nil { showToast(message: "지점을 선택하세요."); return false }
        return true
    }
    
    private func isValidEmail(_ s: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return s.range(of: pattern, options: .regularExpression) != nil
    }
    
    private func showToast(message: String) {
        toastMessage = message
        showToast = true
    }
}
