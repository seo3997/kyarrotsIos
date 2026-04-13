import SwiftUI
import Combine

@MainActor
class MembershipViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var passwordConfirm = ""
    @Published var birth = ""
    @Published var phoneFirst = "010"
    @Published var phoneMid = ""
    @Published var phoneLast = ""
    @Published var gender = 0 // 0: None, 1: Male, 2: Female
    
    @Published var cityList: [TxtListDataInfo] = []
    @Published var townList: [TxtListDataInfo] = []
    @Published var selectedCity: TxtListDataInfo?
    @Published var selectedTown: TxtListDataInfo?
    @Published var selectedRole: String?
    
    @Published var branchList: [BranchInfoVo] = []
    @Published var selectedBranch: BranchInfoVo? = nil
    
    @Published var isEmailChecked = false
    @Published var isLoading = false
    @Published var toastMessage: String?
    @Published var showToast = false
    
    let phoneFirstOptions = ["010", "011", "016", "017", "018", "019"]
    let roleOptions: [String: String] = ["판매자": "ROLE_SELL", "센터관리": "ROLE_PROJ", "구매자": "ROLE_PUB"]
    
    private let service: AppService
    private var cancellables = Set<AnyCancellable>()
    
    init(service: AppService) {
        self.service = service
        self.selectedRole = "구매자"
        
        // 이메일 변경 시 중복확인 리셋
        $email
            .dropFirst()
            .sink { [weak self] _ in
                self?.isEmailChecked = false
            }
            .store(in: &cancellables)
            
        // 생년월일 포맷팅 (YYYY-MM-DD)
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
    
    func loadCityList() async {
        let list = await service.getCodeList(groupId: "R010070")
        self.cityList = list
    }
    
    func loadTownList(cityCode: String) async {
        let list = await service.getSCodeList(groupId: "R010070", mcode: cityCode)
        self.townList = list
        self.selectedTown = nil
    }
    
    func fetchBranchList() async {
        let list = await service.getBranchList()
        await MainActor.run {
            self.branchList = list
        }
    }
    
    func checkEmail() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(trimmedEmail) else {
            showToast(message: "유효한 이메일을 입력하세요.")
            return
        }
        
        isLoading = true
        if let response = await service.checkEmailDuplicate(email: trimmedEmail) {
            isLoading = false
            if response.result {
                showToast(message: "사용 가능한 이메일입니다.")
                isEmailChecked = true
            } else {
                showToast(message: "이미 사용 중인 이메일입니다.")
                isEmailChecked = false
            }
        } else {
            isLoading = false
            showToast(message: "이메일 중복 확인 실패")
        }
    }
    
    func register(completion: @escaping () -> Void) async {
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
        user.areaCode = selectedCity?.strIdx
        user.areaSeCodeS = selectedTown?.strIdx
        user.areaSeCodeD = ""
        user.userSttusCode = "10"
        user.memberCode = roleOptions[selectedRole ?? ""]
        user.provider = "PWD"
        user.referrerId = ""
        guard let branchId = selectedBranch?.branchId else {
            // 여기서 에러 로그를 남기거나 fatalError를 발생시킵니다.
            fatalError("에러 발생: selectedBranch 또는 branchId가 없습니다!")
        }
        user.branchId = String(branchId)
        user.userAge = ""
        
        isLoading = true
        if let res = await service.registerUser(user), res.resultCode == 200 {
            LoginInfoUtil.saveLoginInfo(res, email: email, password: password)
            isLoading = false
            showToast(message: "회원가입 성공!")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completion()
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
        if selectedRole == nil { showToast(message: "사용자구분을 선택하세요."); return false }
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
    
    private func showToast(message: String) {
        toastMessage = message
        showToast = true
    }
}

struct MembershipSwiftUIView: View {
    @StateObject var viewModel: MembershipViewModel
    var onRegisterSuccess: () -> Void
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    Group {
                        CustomTextField(title: "이름", text: $viewModel.name, placeholder: "이름을 입력하세요")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("이메일")
                                .font(.system(size: 14, weight: .semibold))
                            HStack {
                                TextField("이메일을 입력하세요", text: $viewModel.email)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                
                                Button(action: {
                                    Task { await viewModel.checkEmail() }
                                }) {
                                    Text("중복확인")
                                        .font(.system(size: 13, weight: .bold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(viewModel.isEmailChecked ? Color.gray : Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                }
                                .disabled(viewModel.isEmailChecked)
                            }
                        }
                        
                        CustomSecureField(title: "비밀번호", text: $viewModel.password, placeholder: "비밀번호 (4자 이상)")
                        CustomSecureField(title: "비밀번호 확인", text: $viewModel.passwordConfirm, placeholder: "비밀번호를 한번 더 입력하세요")
                        
                        CustomTextField(title: "생년월일", text: $viewModel.birth, placeholder: "YYYY-MM-DD", keyboardType: .numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("전화번호")
                            .font(.system(size: 14, weight: .semibold))
                        HStack {
                            Menu {
                                ForEach(viewModel.phoneFirstOptions, id: \.self) { option in
                                    Button(option) { viewModel.phoneFirst = option }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.phoneFirst)
                                    Image(systemName: "chevron.down").font(.system(size: 12))
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 38)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                            
                            TextField("", text: Binding(
                                get: { viewModel.phoneMid },
                                set: { newValue in
                                    let filtered = newValue.filter { $0.isNumber }
                                    viewModel.phoneMid = String(filtered.prefix(4))
                                }
                            ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                            
                            Text("-")
                            
                            TextField("", text: Binding(
                                get: { viewModel.phoneLast },
                                set: { newValue in
                                    let filtered = newValue.filter { $0.isNumber }
                                    viewModel.phoneLast = String(filtered.prefix(4))
                                }
                            ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("성별")
                            .font(.system(size: 14, weight: .semibold))
                        Picker("성별", selection: $viewModel.gender) {
                            Text("선택 안함").tag(0)
                            Text("남").tag(1)
                            Text("여").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("지점 선택")
                            .font(.system(size: 14, weight: .semibold))
                        HStack {
                            Menu {
                                ForEach(viewModel.branchList, id: \.branchId) { branch in
                                    Button(branch.branchName ?? "이름 없음") {
                                        viewModel.selectedBranch = branch
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.selectedBranch?.branchName ?? "지점을 선택하세요")
                                        .font(.system(size: 15))
                                        .foregroundColor(viewModel.selectedBranch == nil ? .gray : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down").font(.system(size: 12))
                                }
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    
                    Button(action: {
                        Task {
                            await viewModel.register {
                                onRegisterSuccess()
                            }
                        }
                    }) {
                        Text("가입하기")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("회원가입")
            .navigationBarTitleDisplayMode(.inline)
            
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            Task { await viewModel.fetchBranchList() }
        }
        .alert(isPresented: $viewModel.showToast) {
            Alert(title: Text(viewModel.toastMessage ?? ""), message: nil, dismissButton: .default(Text("확인")))
        }
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
        }
    }
}

struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            SecureField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}
