import SwiftUI
import WebKit

struct TermsZoomSwiftUIView: View {
    let title: String
    let url: URL?
    let html: String?
    let textZoomPercent: Int = 140
    
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            TermsWebView(url: url, html: html, textZoomPercent: textZoomPercent) {
                isLoading = false
            }
            .edgesIgnoringSafeArea(.bottom)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsWebView: UIViewRepresentable {
    let url: URL?
    let html: String?
    let textZoomPercent: Int
    let onLoadFinished: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = url {
            uiView.load(URLRequest(url: url))
        } else if let html = html {
            uiView.loadHTMLString(html, baseURL: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onLoadFinished: onLoadFinished, textZoomPercent: textZoomPercent)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var onLoadFinished: () -> Void
        var textZoomPercent: Int
        
        init(onLoadFinished: @escaping () -> Void, textZoomPercent: Int) {
            self.onLoadFinished = onLoadFinished
            self.textZoomPercent = textZoomPercent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let scale = Double(textZoomPercent) / 100.0
            let js = "document.body.style.zoom = '\(scale)';"
            webView.evaluateJavaScript(js, completionHandler: nil)
            onLoadFinished()
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onLoadFinished()
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onLoadFinished()
        }
    }
}

#Preview {
    TermsZoomSwiftUIView(title: "이용약관", url: URL(string: "https://www.google.com"), html: nil)
}
