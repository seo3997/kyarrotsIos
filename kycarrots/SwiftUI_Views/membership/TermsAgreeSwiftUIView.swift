import SwiftUI
import WebKit

struct TermsAgreeSwiftUIView: View {
    @State private var agreeAll = false
    @State private var agree1 = false
    @State private var agree2 = false
    
    @State private var showZoom1 = false
    @State private var showZoom2 = false
    
    @State private var isLoading1 = true
    @State private var isLoading2 = true
    
    var onNext: () -> Void
    var onCancel: () -> Void
    var onShowZoom: (String, String) -> Void
    
    private var terms1Url: String {
        Constants.BASE_URL + "link/join_terms1.do"
    }
    
    private var terms2Url: String {
        Constants.BASE_URL + "link/join_terms2.do"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 전체 동의
                    Button(action: {
                        agreeAll.toggle()
                        agree1 = agreeAll
                        agree2 = agreeAll
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: agreeAll ? "checkmark.square.fill" : "square")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                            Text("전체 동의")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // 이용약관
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            agree1.toggle()
                            updateAgreeAll()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: agree1 ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)
                                Text("동의합니다 (필수)")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("이용약관")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        ZStack {
                            MiniWebView(url: URL(string: terms1Url), isLoading: $isLoading1) {
                                onShowZoom("이용약관", terms1Url)
                            }
                            .frame(height: 230)
                            .background(Color(white: 0.95))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                            if isLoading1 {
                                ProgressView()
                                    .scaleEffect(1.2)
                            }
                        }
                    }
                    
                    // 개인정보 수집 이용 동의
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            agree2.toggle()
                            updateAgreeAll()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: agree2 ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)
                                Text("동의합니다 (필수)")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("개인정보 수집·이용 동의")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        ZStack {
                            MiniWebView(url: URL(string: terms2Url), isLoading: $isLoading2) {
                                onShowZoom("개인정보 수집·이용 동의", terms2Url)
                            }
                            .frame(height: 230)
                            .background(Color(white: 0.95))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                            if isLoading2 {
                                ProgressView()
                                    .scaleEffect(1.2)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 하단 버튼
            HStack(spacing: 16) {
                Button(action: onCancel) {
                    Text("취소")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(white: 0.9))
                        .cornerRadius(12)
                }
                
                Button(action: onNext) {
                    Text("다음")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(agree1 && agree2 ? Color.accentColor : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!(agree1 && agree2))
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
        }
        .navigationTitle("회원가입")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func updateAgreeAll() {
        agreeAll = agree1 && agree2
    }
}

// 미니 웹뷰 (약관 박스용)
struct MiniWebView: UIViewRepresentable {
    let url: URL?
    @Binding var isLoading: Bool
    var onTap: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tapGesture.delegate = context.coordinator
        webView.addGestureRecognizer(tapGesture)
        
        if let url = url {
            webView.load(URLRequest(url: url))
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate, WKNavigationDelegate {
        var parent: MiniWebView
        
        init(parent: MiniWebView) {
            self.parent = parent
        }
        
        @objc func handleTap() {
            parent.onTap()
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        // WKNavigationDelegate methods
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
    }
}

#Preview {
    TermsAgreeSwiftUIView(onNext: {}, onCancel: {}, onShowZoom: { _, _ in })
}
