import SwiftUI

struct OnboardingSwiftUIView: View {
    @StateObject var viewModel: OnboardingViewModel
    var onSuccess: () -> Void
    
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
                                    
                                    TextField("", text: $viewModel.phoneMid)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                                    
                                    Text("-")
                                    
                                    TextField("", text: $viewModel.phoneLast)
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
                                Text("지역")
                                    .font(.system(size: 14, weight: .semibold))
                                HStack {
                                    Menu {
                                        ForEach(viewModel.cityList, id: \.strIdx) { city in
                                            Button(city.strMsg) {
                                                viewModel.selectedCity = city
                                                Task { await viewModel.loadTownList(cityCode: city.strIdx) }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(viewModel.selectedCity?.strMsg ?? "시/도 선택")
                                            Spacer()
                                            Image(systemName: "chevron.down").font(.system(size: 12))
                                        }
                                        .padding(.horizontal, 12)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 38)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(8)
                                    }
                                    
                                    Menu {
                                        ForEach(viewModel.townList, id: \.strIdx) { town in
                                            Button(town.strMsg) {
                                                viewModel.selectedTown = town
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(viewModel.selectedTown?.strMsg ?? "구/군 선택")
                                            Spacer()
                                            Image(systemName: "chevron.down").font(.system(size: 12))
                                        }
                                        .padding(.horizontal, 12)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 38)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(8)
                                        .opacity(viewModel.selectedCity == nil ? 0.5 : 1.0)
                                    }
                                    .disabled(viewModel.selectedCity == nil)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("사용자구분")
                                    .font(.system(size: 14, weight: .semibold))
                                Menu {
                                    let roles = Array(viewModel.roleOptions.keys).sorted()
                                    ForEach(roles, id: \.self) { role in
                                        Button(role) {
                                            viewModel.selectedRole = role
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(viewModel.selectedRole ?? "사용자구분 선택")
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
