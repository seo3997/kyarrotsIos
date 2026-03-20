import SwiftUI

struct FindAccountSwiftUIView: View {
    @StateObject var viewModel: FindAccountViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            // Segmented Picker for Tab
            Picker("아이디 / 비밀번호 찾기", selection: $viewModel.selectedTab) {
                Text("이메일 찾기").tag(0)
                Text("비밀번호 찾기").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if viewModel.selectedTab == 0 {
                FindEmailView(viewModel: viewModel)
            } else {
                FindPasswordView(viewModel: viewModel)
            }
            
            Spacer()
        }
        .navigationTitle("아이디 / 비밀번호 찾기")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onDismiss = { presentationMode.wrappedValue.dismiss() }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertMessage ?? ""),
                dismissButton: .default(Text("확인")) {
                    viewModel.handleAlertDismiss()
                }
            )
        }
    }
}

// MARK: - Email Finding View
struct FindEmailView: View {
    @ObservedObject var viewModel: FindAccountViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("이름")
                    .font(.system(size: 14, weight: .semibold))
                TextField("이름을 입력하세요", text: $viewModel.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("휴대폰 번호")
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
                        .onChange(of: viewModel.phoneMid) { newValue in
                            if newValue.count > 4 { viewModel.phoneMid = String(newValue.prefix(4)) }
                        }
                    
                    Text("-")
                    
                    TextField("", text: $viewModel.phoneLast)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onChange(of: viewModel.phoneLast) { newValue in
                            if newValue.count > 4 { viewModel.phoneLast = String(newValue.prefix(4)) }
                        }
                }
            }
            
            Button(action: {
                Task { await viewModel.findEmail() }
            }) {
                Text("이메일 찾기")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding(.horizontal)
    }
}

// MARK: - Password Reset View
struct FindPasswordView: View {
    @ObservedObject var viewModel: FindAccountViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("가입 이메일")
                    .font(.system(size: 14, weight: .semibold))
                TextField("이메일을 입력하세요", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
            
            Button(action: {
                Task { await viewModel.findPassword() }
            }) {
                Text("비밀번호 찾기")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            Text("입력하신 이메일로 비밀번호 초기화 안내가 전송됩니다.")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }
}
