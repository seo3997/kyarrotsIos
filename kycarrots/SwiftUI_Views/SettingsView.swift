import SwiftUI
import Combine
import FirebaseMessaging
import PhotosUI

class SettingsViewModel: ObservableObject {
    @Published var userInfo: OpUserVO?
    
    // User Edit Form
    @Published var editName: String = ""
    @Published var editContact: String = ""
    
    // Push settings
    @Published var isPushOn: Bool = UserDefaults.standard.object(forKey: "push_enabled") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(isPushOn, forKey: "push_enabled")
            showToastMessage(isPushOn ? "푸시 알림이 켜졌습니다." : "푸시 알림이 꺼졌습니다.")
        }
    }
    
    // Password settings
    @Published var showPasswordChange: Bool = false
    @Published var currentPw: String = ""
    @Published var newPw: String = ""
    @Published var confirmPw: String = ""
    
    // Alerts/Toasts
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var showLogoutAlert: Bool = false
    
    // Local Profile Image
    @Published var selectedPhotoItem: PhotosPickerItem? = nil {
        didSet { loadTransferable(from: selectedPhotoItem) }
    }
    @Published var profileImage: Image? = nil
    
    // Loading state to prevent onChange triggers
    @Published var isFirstLoad: Bool = true
    
    private let appService = AppServiceProvider.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadLocalProfileImage()
        setupContactFormatter()
    }
    
    private func setupContactFormatter() {
        $editContact
            .sink { [weak self] newValue in
                guard let self = self else { return }
                
                // 1. Filter numbers only
                let filtered = newValue.filter { $0.isNumber }
                
                // 2. Limit to 11 digits
                let digits = String(filtered.prefix(11))
                
                // 3. Format with hyphens
                var formatted = ""
                if digits.count <= 3 {
                    formatted = digits
                } else if digits.count <= 6 {
                    // 010123 -> 010-123
                    let first = digits.prefix(3)
                    let mid = digits.dropFirst(3)
                    formatted = "\(first)-\(mid)"
                } else if digits.count <= 10 {
                    // 0101234567 -> 010-123-4567
                    let first = digits.prefix(3)
                    let mid = digits.dropFirst(3).prefix(3)
                    let last = digits.dropFirst(6)
                    formatted = "\(first)-\(mid)-\(last)"
                } else {
                    // 01012345678 -> 010-1234-5678
                    let first = digits.prefix(3)
                    let mid = digits.dropFirst(3).prefix(4)
                    let last = digits.dropFirst(7)
                    formatted = "\(first)-\(mid)-\(last)"
                }
                
                if formatted != newValue {
                    DispatchQueue.main.async {
                        self.editContact = formatted
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func loadUserInfo() {
        let token = TokenUtil.getToken()
        guard !token.isEmpty else { return }
        
        self.isFirstLoad = true
        
        Task {
            do {
                if let info = try await appService.getUserInfoByToken(token: token) {
                    self.userInfo = info
                    self.editName = info.userNm ?? ""
                    self.editContact = info.cttpc ?? ""
                    
                }
                self.isFirstLoad = false
            } catch {
                print("getUserInfo Error:", error)
                self.isFirstLoad = false
            }
        }
    }
    
    
    @MainActor
    func saveUserInfo() {
        let token = TokenUtil.getToken()
        guard !token.isEmpty else { return }
        guard let info = userInfo else { return }
        
        if editName.isEmpty || editContact.isEmpty {
            showToastMessage("모든 정보를 입력해주세요.")
            return
        }
        
        var updatedUser = info
        updatedUser.userNm = editName
        updatedUser.cttpc = editContact
        
        Task {
            let success = await appService.updateUser(token: token, user: updatedUser)
            if success {
                showToastMessage("정보가 수정되었습니다.")
                self.userInfo = updatedUser
            } else {
                showToastMessage("수정에 실패했습니다.")
            }
        }
    }
    
    @MainActor
    func executePasswordChange() {
        if currentPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty {
            showToastMessage("비밀번호를 모두 입력해주세요.")
            return
        }
        if newPw != confirmPw {
            showToastMessage("새 비밀번호가 일치하지 않습니다.")
            return
        }
        
        let token = TokenUtil.getToken()
        guard !token.isEmpty else { return }
        let req = PasswordChangeRequest(currentPassword: currentPw, newPassword: newPw, confirmPassword: confirmPw)
        
        Task {
            let (success, msg) = await appService.changePassword(token: token, request: req)
            if success {
                showToastMessage(msg.isEmpty ? "비밀번호가 변경되었습니다." : msg)
                self.currentPw = ""
                self.newPw = ""
                self.confirmPw = ""
                self.showPasswordChange = false
            } else {
                showToastMessage(msg.isEmpty ? "변경에 실패했습니다." : msg)
            }
        }
    }
    
    func togglePasswordChange() {
        showPasswordChange.toggle()
        if showPasswordChange {
            currentPw = ""
            newPw = ""
            confirmPw = ""
        }
    }
    
    private func loadTransferable(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data?):
                    if let uiImage = UIImage(data: data) {
                        self.profileImage = Image(uiImage: uiImage)
                        self.saveLocalProfileImage(data: data)
                    }
                case .success(nil), .failure:
                    break
                }
            }
        }
    }
    
    private func saveLocalProfileImage(data: Data) {
        let url = ProfileImageUtil.getProfileImageUrl()
        try? data.write(to: url)
    }
    
    private func loadLocalProfileImage() {
        if let uiImage = ProfileImageUtil.getLocalProfileImage() {
            self.profileImage = Image(uiImage: uiImage)
        }
    }
    

    
    func logout() {
        let memberCode = LoginInfoUtil.getMemberCode()
        if !memberCode.isEmpty {
            Messaging.messaging().unsubscribe(fromTopic: memberCode)
        }
        LoginInfoUtil.clearLoginInfo()
        TokenUtil.clearToken()
        DispatchQueue.main.async {
            UIApplication.shared.appCoordinator?.showLogin(pendingDeepLink: nil)
        }
    }
    
    func showToastMessage(_ msg: String) {
        self.toastMessage = msg
        withAnimation { self.showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { self.showToast = false }
        }
    }
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // 프로필 섹션
                    VStack(spacing: 16) {
                        PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            ZStack(alignment: .bottomTrailing) {
                                if let profileImage = viewModel.profileImage {
                                    profileImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(Color(white: 0.8))
                                        .background(Color(white: 0.95))
                                        .clipShape(Circle())
                                }
                                
                                // 카메라 아이콘 표시
                                Image(systemName: "camera.circle.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .font(.system(size: 24))
                                    .background(Circle().fill(Color.white))
                                    .offset(x: 4, y: 4)
                            }
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("아이디:")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, alignment: .leading)
                                Text(viewModel.userInfo?.userId ?? "")
                                    .font(.system(size: 15))
                                Spacer()
                            }
                            
                            HStack {
                                Text("이름")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, alignment: .leading)
                                TextField("이름", text: $viewModel.editName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            HStack {
                                Text("연락처")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, alignment: .leading)
                                TextField("연락처", text: $viewModel.editContact)
                                    .keyboardType(.phonePad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                                                        
                            Button(action: {
                                viewModel.saveUserInfo()
                            }) {
                                Text("사용자 정보 수정 완료")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    Divider()
                    
                    // 앱 설정 섹션
                    VStack(alignment: .leading, spacing: 16) {
                        Text("앱 설정")
                            .font(.headline)
                        
                        Toggle("푸시 알림", isOn: $viewModel.isPushOn)
                            .padding(.vertical, 4)
                        
                        Button(action: {
                            withAnimation {
                                viewModel.togglePasswordChange()
                            }
                        }) {
                            HStack {
                                Text("비밀번호 변경")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: viewModel.showPasswordChange ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // 비밀번호 변경 Layout
                        if viewModel.showPasswordChange {
                            VStack(spacing: 12) {
                                SecureField("현재 비밀번호", text: $viewModel.currentPw)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                SecureField("새 비밀번호", text: $viewModel.newPw)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                SecureField("새 비밀번호 확인", text: $viewModel.confirmPw)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Button(action: {
                                    viewModel.executePasswordChange()
                                }) {
                                    Text("비밀번호 변경 실행")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    // 로그아웃 버튼
                    Button(action: {
                        viewModel.showLogoutAlert = true
                    }) {
                        Text("로그아웃")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                }
                .padding(20)
            }
            
            // Toast Overlay
            if viewModel.showToast {
                VStack {
                    Spacer()
                    Text(viewModel.toastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle("프로필 / 설정")
        .navigationBarHidden(false) // ✅ 네비게이션 바 강제 표시
        .navigationBarBackButtonHidden(true) // ✅ 뒤로가기 버튼 숨김
        .alert("로그아웃", isPresented: $viewModel.showLogoutAlert) {
            Button("취소", role: .cancel) { }
            Button("로그아웃", role: .destructive) {
                viewModel.logout()
            }
        } message: {
            Text("정말 로그아웃 하시겠어요?")
        }
        .onAppear {
            viewModel.loadUserInfo()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
