import SwiftUI

struct OnboardingSwiftUIView: View {
    @StateObject var viewModel: OnboardingViewModel
    var onSuccess: () -> Void
    
    // ✅ 커스텀 바인딩을 사용하여 입력 단계에서 4자리를 넘지 못하도록 즉시 차단
    private var phoneMidBinding: Binding<String> {
        Binding(
            get: { viewModel.phoneMid },
            set: { newValue in
                let filtered = newValue.filter { $0.isNumber }
                let capped = String(filtered.prefix(4))
                
                if filtered.count > 4 {
                    // 4자리 초과 시 즉시 알림 노출
                    viewModel.toastMessage = "전화번호는 4자리까지 입력 가능합니다."
                    viewModel.showToast = true
                }
                
                if viewModel.phoneMid != capped {
                    viewModel.phoneMid = capped
                } else if filtered.count > 4 {
                    // 값이 같더라도 UI 갱신을 위해 강제 트리거
                    let current = viewModel.phoneMid
                    viewModel.phoneMid = ""
                    DispatchQueue.main.async {
                        viewModel.phoneMid = current
                    }
                }
            }
        )
    }

    private var phoneLastBinding: Binding<String> {
        Binding(
            get: { viewModel.phoneLast },
            set: { newValue in
                let filtered = newValue.filter { $0.isNumber }
                let capped = String(filtered.prefix(4))
                
                if filtered.count > 4 {
                    viewModel.toastMessage = "전화번호는 4자리까지 입력 가능합니다."
                    viewModel.showToast = true
                }
                
                if viewModel.phoneLast != capped {
                    viewModel.phoneLast = capped
                } else if filtered.count > 4 {
                    let current = viewModel.phoneLast
                    viewModel.phoneLast = ""
                    DispatchQueue.main.async {
                        viewModel.phoneLast = current
                    }
                }
            }
        )
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    Group {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("이메일")
                                .font(.system(size: 14, weight: .semibold))
                            HStack {
                                TextField("이메일을 입력하세요", text: $viewModel.email)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                
                                Button(action: {
                                    Task { await viewModel.checkEmail(onLinkSuccess: onSuccess) }
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
                            
                            if !viewModel.emailStatusMessage.isEmpty {
                                Text(viewModel.emailStatusMessage)
                                    .font(.caption)
                                    .foregroundColor(viewModel.isEmailChecked ? .blue : .red)
                            }
                        }
                    }
                    
                    if viewModel.isFormVisible {
                        Group {
                            OnboardingCustomTextField(title: "이름", text: $viewModel.name, placeholder: "이름을 입력하세요")
                            
                            OnboardingCustomSecureField(title: "비밀번호", text: $viewModel.password, placeholder: "비밀번호 (4자 이상)")
                            OnboardingCustomSecureField(title: "비밀번호 확인", text: $viewModel.passwordConfirm, placeholder: "비밀번호를 한번 더 입력하세요")
                            
                            OnboardingCustomTextField(title: "생년월일", text: $viewModel.birth, placeholder: "YYYY-MM-DD", keyboardType: .numberPad)
                            
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
                                    
                                    TextField("", text: phoneMidBinding)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                                    
                                    Text("-")
                                    
                                    TextField("", text: phoneLastBinding)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("성별")
                                    .font(.system(size: 14, weight: .semibold))
                                Picker("성별", selection: $viewModel.gender) {
                                    Text("남").tag(1)
                                    Text("여").tag(2)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("지점선택")
                                    .font(.system(size: 14, weight: .semibold))
                                Menu {
                                    ForEach(viewModel.branchList, id: \.branchId) { branch in
                                        Button(branch.branchName ?? "") {
                                            viewModel.selectedBranch = branch
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(viewModel.selectedBranch?.branchName ?? "지점을 선택하세요")
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
                            
                            Button(action: {
                                Task {
                                    await viewModel.register {
                                        onSuccess()
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
                    }
                }
                .padding()
            }
            .navigationTitle("추가정보입력")
            .navigationBarTitleDisplayMode(.inline)
            
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            Task { await viewModel.loadInitialData() }
        }
        .alert(isPresented: $viewModel.showToast) {
            Alert(title: Text(viewModel.toastMessage ?? ""), message: nil, dismissButton: .default(Text("확인")))
        }
    }
}

// MARK: - Local UI Components
struct OnboardingCustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var limit: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
                .onChange(of: text) { newValue in
                    if let limit = limit, newValue.count > limit {
                        text = String(newValue.prefix(limit))
                    }
                }
        }
    }
}

struct OnboardingCustomSecureField: View {
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
