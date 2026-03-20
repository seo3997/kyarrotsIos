import SwiftUI
import Combine

@MainActor
class FindAccountViewModel: ObservableObject {
    
    // MARK: - Navigation State
    @Published var selectedTab = 0 // 0: Find Email, 1: Find Password
    
    // MARK: - Find Email State
    @Published var name = ""
    @Published var phoneFirst = "010"
    @Published var phoneMid = ""
    @Published var phoneLast = ""
    
    // MARK: - Find Password State
    @Published var email = ""
    
    // MARK: - Common State
    @Published var isLoading = false
    @Published var alertMessage: String?
    @Published var showAlert = false
    var onDismiss: () -> Void = {}
    
    let phoneFirstOptions = ["010", "011", "016", "017", "018", "019"]
    private let service: AppService
    
    init(service: AppService) {
        self.service = service
    }
    
    // MARK: - Actions
    func findEmail() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let mid = phoneMid.filter { $0.isNumber }
        let last = phoneLast.filter { $0.isNumber }
        
        if trimmedName.isEmpty { displayAlert("이름을 입력해 주세요."); return }
        if mid.isEmpty || last.isEmpty { displayAlert("휴대폰 번호를 입력해 주세요."); return }
        
        let phone = "\(phoneFirst)-\(mid)-\(last)"
        
        isLoading = true
        let result = await service.findEmail(name: trimmedName, phone: phone)
        isLoading = false
        
        if let msg = result, !msg.isEmpty {
            displayAlert(msg) { self.onDismiss() }
        } else {
            displayAlert("가입된 이메일이 없습니다.")
        }
    }
    
    func findPassword() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedEmail.isEmpty { displayAlert("이메일을 입력해 주세요."); return }
        if !isValidEmail(trimmedEmail) { displayAlert("이메일 형식이 올바르지 않습니다."); return }
        
        isLoading = true
        
        // Directly call service logic (migrated from deleted FindPassword class)
        let resultCode: Int
        do {
            let codeStr = (try await service.findPassword(email: trimmedEmail) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let code = Int(codeStr) {
                resultCode = code
            } else {
                resultCode = StaticDataInfo.RESULT_CODE_ERR
            }
        } catch {
            resultCode = StaticDataInfo.RESULT_CODE_ERR
        }
        
        isLoading = false
        
        switch resultCode {
        case StaticDataInfo.RESULT_CODE_200:
            displayAlert("비밀번호 초기화 안내 메일을\n\(trimmedEmail) 로 전송했습니다.") { self.onDismiss() }
        case StaticDataInfo.RESULT_NO_USER, StaticDataInfo.RESULT_NO_DATA:
            displayAlert("가입된 회원 정보가 없습니다.")
        case StaticDataInfo.RESULT_NO_SOCAIL_DATA:
            displayAlert("소셜 로그인 회원은 비밀번호를 변경할 수 없습니다.")
        default:
            displayAlert("알 수 없는 오류가 발생했습니다. (code: \(resultCode))")
        }
    }
    
    private func displayAlert(_ message: String, completion: @escaping () -> Void = {}) {
        alertMessage = message
        showAlert = true
        // Store completion to be called when alert is dismissed
        self.alertCompletion = completion
    }
    
    private var alertCompletion: () -> Void = {}
    func handleAlertDismiss() {
        alertCompletion()
    }
    
    private func isValidEmail(_ s: String) -> Bool {
        return s.contains("@") && s.contains(".")
    }
}
