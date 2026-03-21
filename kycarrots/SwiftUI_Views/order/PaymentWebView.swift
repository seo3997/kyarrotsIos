import SwiftUI
import WebKit

struct PaymentWebView: View {
    let orderResponse: OrderCreateResponse
    var onComplete: (Bool) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let service = AppService(repo: RemoteRepository())
    
    var body: some View {
        NavigationView {
            ZStack {
                PaymentWKWebView(
                    orderResponse: orderResponse,
                    onSuccess: { paymentKey, orderNo, amount in
                        confirmPayment(paymentKey: paymentKey, orderNo: orderNo, amount: amount)
                    },
                    onFail: { message in
                        errorMessage = message
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            onComplete(false)
                        }
                    }
                )
                
                if isLoading {
                    Color.white.opacity(0.8)
                        .ignoresSafeArea()
                    ProgressView("결제 승인 중...")
                }
            }
            .navigationTitle("결제하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                }
            }
            .alert("결제 알림", isPresented: Binding(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Button("확인", role: .cancel) { }
            } message: {
                if let msg = errorMessage {
                    Text(msg)
                }
            }
        }
    }
    
    private func confirmPayment(paymentKey: String, orderNo: String, amount: Int) {
        isLoading = true
        Task {
            let userNo = Int64(LoginInfoUtil.getUserNo())
            let request = PaymentConfirmRequest(
                paymentKey: paymentKey,
                orderNo: orderNo,
                amount: amount,
                userNo: userNo
            )
            
            let success = await service.confirmPayment(req: request)
            await MainActor.run {
                isLoading = false
                if success {
                    onComplete(true)
                } else {
                    errorMessage = "결제 승인에 실패했습니다."
                }
            }
        }
    }
}

struct PaymentWKWebView: UIViewRepresentable {
    let orderResponse: OrderCreateResponse
    var onSuccess: (String, String, Int) -> Void
    var onFail: (String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        
        let clientKey = LoginInfoUtil.getTossClientKey()
        let successUrl = "https://kycarrots.com/payment-success"
        let failUrl = "https://kycarrots.com/payment-fail"
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <script src="https://js.tosspayments.com/v1"></script>
        </head>
        <body>
            <script>
                document.addEventListener("DOMContentLoaded", function() {
                    try {
                        var tossPayments = TossPayments("\(clientKey)");
                        tossPayments.requestPayment('CARD', {
                            amount: \(orderResponse.amount),
                            orderId: '\(orderResponse.orderNo)',
                            orderName: '\(orderResponse.orderName ?? "상품 구매")',
                            successUrl: '\(successUrl)',
                            failUrl: '\(failUrl)',
                        });
                    } catch (e) {
                        console.error("TossPayments error:", e);
                    }
                });
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: URL(string: "https://tosspayments.com"))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PaymentWKWebView
        
        init(_ parent: PaymentWKWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            let urlString = url.absoluteString
            
            // Handle Success/Fail Redirects
            if urlString.contains("payment-success") {
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let queryItems = components.queryItems {
                    let paymentKey = queryItems.first(where: { $0.name == "paymentKey" })?.value ?? ""
                    let orderNo = queryItems.first(where: { $0.name == "orderId" })?.value ?? ""
                    let amount = Int(queryItems.first(where: { $0.name == "amount" })?.value ?? "0") ?? 0
                    
                    parent.onSuccess(paymentKey, orderNo, amount)
                    decisionHandler(.cancel)
                    return
                }
            } else if urlString.contains("payment-fail") {
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let queryItems = components.queryItems {
                    let message = queryItems.first(where: { $0.name == "message" })?.value ?? "결제에 실패했습니다."
                    parent.onFail(message)
                    decisionHandler(.cancel)
                    return
                }
            }
            
            // Handle Custom URL Schemes for Card Apps
            if !["http", "https", "about", "data"].contains(url.scheme?.lowercased()) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    decisionHandler(.cancel)
                    return
                }
            }
            
            decisionHandler(.allow)
        }
    }
}
