import SwiftUI

struct LoginSwiftUIView: View {
    @StateObject var viewModel: LoginViewModel
    
    var body: some View {
        ZStack {
            // Background Image
            Image("login_bg")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .overlay(Color.black.opacity(0.3)) // Optional overlay for better text contrast
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo
                Image("logo4")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                
                Spacer().frame(height: 40)
                
                // Login Fields Container
                VStack(spacing: 16) {
                    CustomLoginTextField(
                        icon: "envelope",
                        placeholder: "이메일",
                        text: $viewModel.email,
                        keyboardType: .emailAddress
                    )
                    
                    CustomLoginSecureField(
                        icon: "lock",
                        placeholder: "비밀번호",
                        text: $viewModel.password
                    )
                    
                    Button(action: {
                        Task { await viewModel.login() }
                    }) {
                        Text("로그인")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 40)
                
                // Social Logins
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.loginWithKakao()
                    }) {
                        HStack {
                            Image("ic_kakao_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            Text("카카오 로그인")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.black.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(red: 254/255, green: 229/255, blue: 0))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        viewModel.unlinkKakao()
                    }) {
                        Text("카카오 연결 해제")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 40)
                
                // Footer Buttons (Membership / Find)
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.onShowMembership()
                    }) {
                        Text("회원가입")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Divider().frame(height: 14).background(Color.white)
                    
                    Button(action: {
                        viewModel.onShowFindAccount()
                    }) {
                        Text("아이디/비밀번호 찾기")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 10)
                
                Spacer()
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .alert(isPresented: $viewModel.showToast) {
            Alert(
                title: Text(viewModel.toastMessage ?? ""),
                dismissButton: .default(Text("확인"))
            )
        }
    }
}

// MARK: - Components
struct CustomLoginTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder).foregroundColor(.white.opacity(0.7))
                }
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Color.white.opacity(0.2))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CustomLoginSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            SecureField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder).foregroundColor(.white.opacity(0.7))
                }
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Color.white.opacity(0.2))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

// Extension for SwiftUI placeholder visibility
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
