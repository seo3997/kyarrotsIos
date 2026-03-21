import SwiftUI
import WebKit

struct AddressSearchResult {
    let zipCode: String
    let address: String
}

struct AddressSearchView: View {
    var onSelect: (AddressSearchResult) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            AddressWebView(onSelect: onSelect)
                .navigationTitle("주소 검색")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("취소") { dismiss() }
                    }
                }
        }
    }
}

struct AddressWebView: UIViewRepresentable {
    var onSelect: (AddressSearchResult) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "iOS")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        
        // Daum Postcode HTML
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
            <script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
            <style>
                html, body, #layer { width:100%; height:100%; margin:0; padding:0; }
            </style>
        </head>
        <body>
            <div id="layer"></div>
            <script>
                var element_layer = document.getElementById('layer');
                new daum.Postcode({
                    oncomplete: function(data) {
                        if (window.webkit && window.webkit.messageHandlers.iOS) {
                            window.webkit.messageHandlers.iOS.postMessage({
                                "zipCode": data.zonecode,
                                "address": data.address
                            });
                        }
                    },
                    width : '100%',
                    height : '100%'
                }).embed(element_layer);
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: URL(string: "https://daum.net"))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: AddressWebView
        
        init(parent: AddressWebView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "iOS", let dict = message.body as? [String: String] {
                let zipCode = dict["zipCode"] ?? ""
                let address = dict["address"] ?? ""
                parent.onSelect(AddressSearchResult(zipCode: zipCode, address: address))
            }
        }
    }
}
