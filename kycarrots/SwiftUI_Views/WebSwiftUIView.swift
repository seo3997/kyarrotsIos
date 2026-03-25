import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct WebSwiftUIView: View {
    let urlString: String
    let title: String
    
    @State private var isLoading = false
    @State private var progress: Double = 0
    @State private var webView = WKWebView()
    
    // Notification logic
    var onShowNotifications: (() -> Void)?
    
    // Toast simulation
    @State private var toastMessage: String?
    @State private var showToast = false
    
    var body: some View {
        ZStack(alignment: .top) {
            WebView(urlString: urlString, progress: $progress, isLoading: $isLoading, webView: webView, toastMessage: $toastMessage, showToast: $showToast)
            
            if isLoading && progress < 1.0 {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                    .frame(height: 3)
                    .transition(.opacity)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NotificationBellButton {
                    onShowNotifications?()
                }
            }
        }
        .navigationBarBackButtonHidden(true) // ✅ 뒤로가기 버튼 숨김
        .alert(isPresented: $showToast) {
            Alert(title: Text(toastMessage ?? ""), message: nil, dismissButton: .default(Text("확인")))
        }
    }
}

struct WebView: UIViewRepresentable {
    let urlString: String
    @Binding var progress: Double
    @Binding var isLoading: Bool
    let webView: WKWebView
    
    @Binding var toastMessage: String?
    @Binding var showToast: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // UserAgent
        webView.customUserAgent = (webView.customUserAgent ?? "") + " KyCarrotsApp/iOS"
        
        // JS Bridge
        webView.configuration.userContentController.add(context.coordinator, name: "iOSBridge")
        
        // JS Enabling
        webView.configuration.preferences.javaScriptEnabled = true
        
        // Refresh Control
        let refresh = UIRefreshControl()
        refresh.addTarget(context.coordinator, action: #selector(Coordinator.onRefresh), for: .valueChanged)
        webView.scrollView.refreshControl = refresh
        
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebView
        var progressObservation: NSKeyValueObservation?
        var openPanelCompletion: (([URL]?) -> Void)?
        
        init(_ parent: WebView) {
            self.parent = parent
            super.init()
            
            self.progressObservation = parent.webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
                guard let self = self, let newVal = change.newValue else { return }
                DispatchQueue.main.async {
                    self.parent.progress = newVal
                    self.parent.isLoading = newVal < 1.0
                }
            }
        }
        
        deinit {
            progressObservation?.invalidate()
            parent.webView.configuration.userContentController.removeScriptMessageHandler(forName: "iOSBridge")
        }
        
        @objc func onRefresh(_ sender: UIRefreshControl) {
            parent.webView.reload()
            sender.endRefreshing()
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url,
                  let scheme = url.scheme?.lowercased() else {
                decisionHandler(.allow)
                return
            }
            
            if ["tel", "mailto", "sms"].contains(scheme) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }
            
            if url.absoluteString.hasPrefix("intent://") {
                if let fallback = URL(string: url.absoluteString.replacingOccurrences(of: "intent://", with: "https://")) {
                    UIApplication.shared.open(fallback, options: [:], completionHandler: nil)
                }
                decisionHandler(.cancel)
                return
            }
            
            if scheme != "http" && scheme != "https" {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.webView.scrollView.refreshControl?.endRefreshing()
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.webView.scrollView.refreshControl?.endRefreshing()
            parent.isLoading = false
            showToast("페이지를 불러오지 못했습니다.")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.webView.scrollView.refreshControl?.endRefreshing()
            parent.isLoading = false
            showToast("페이지를 불러오지 못했습니다.")
        }
        
        private func showToast(_ msg: String) {
            DispatchQueue.main.async {
                self.parent.toastMessage = msg
                self.parent.showToast = true
            }
        }
        
        // MARK: - WKUIDelegate
        func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
            self.openPanelCompletion = completionHandler
            
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
            picker.delegate = self
            picker.allowsMultipleSelection = parameters.allowsMultipleSelection
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                var topController = rootVC
                while let newTop = topController.presentedViewController {
                    topController = newTop
                }
                topController.present(picker, animated: true)
            }
        }
        
        // MARK: - WKScriptMessageHandler
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "iOSBridge" else { return }
            
            if let dict = message.body as? [String: Any] {
                let type = dict["type"] as? String ?? ""
                switch type {
                case "showToast":
                    if let msg = dict["message"] as? String {
                        showToast(msg)
                    }
                case "refresh":
                    parent.webView.reload()
                default:
                    break
                }
            } else if let str = message.body as? String {
                showToast(str)
            }
        }
    }
}

extension WebView.Coordinator: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        openPanelCompletion?(nil)
        openPanelCompletion = nil
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        openPanelCompletion?(urls)
        openPanelCompletion = nil
    }
}
