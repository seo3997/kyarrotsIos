//
//  ProductDescriptionView.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//

import SwiftUI
import WebKit
import Kingfisher

struct ProductDescriptionView: View {
    @ObservedObject var viewModel: ProductDetailViewModel
    @State private var webViewHeight: CGFloat = 1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let productDetail = viewModel.productDetail {
                let product = productDetail.product
                
                VStack(alignment: .leading, spacing: 16) {
                    // 1. Description (Moved to Top)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("상품 설명")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.bottom, 4)
                        
                        if product.editorMode == "1" || product.editorMode == "2" {
                            let rawDescription = product.description ?? "설명이 없습니다"
                            let htmlContent = wrapHTML(rawDescription)
                            HTMLStringView(htmlContent: htmlContent, height: $webViewHeight)
                                .frame(height: webViewHeight)
                                .transition(.opacity)
                        } else {
                            Text(product.description ?? "설명이 없습니다")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)

                    // 2. Price & Shipping
                    VStack(alignment: .leading, spacing: 16) {
                        let priceValue = Int(Double(product.price ?? "0") ?? 0)
                        Text("\(CurrencyUtil.formatCurrency(priceValue))")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.blue)
                        
                        Divider()
                        
                        HStack(spacing: 12) {
                            Image(systemName: "shippingbox.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("배송비: \(CurrencyUtil.formatCurrency(viewModel.baseShippingFee))")
                                    .font(.system(size: 17, weight: .bold))
                                Text("(\(CurrencyUtil.formatCurrency(viewModel.freeShippingThreshold)) 이상 구매 시 무료)")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.1), lineWidth: 1))
                        
                        let availQtyValue = Int(Double(product.availableQuantity ?? "0") ?? 0)
                        Text("구매 가능 수량: \(CurrencyUtil.formatCurrency(availQtyValue))개")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 16) {
                            Text("수량").font(.system(size: 17, weight: .bold))
                            Spacer()
                            HStack(spacing: 12) {
                                Button(action: { if viewModel.quantity > 1 { viewModel.quantity -= 1 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(viewModel.quantity > 1 ? .blue : .gray.opacity(0.3))
                                }
                                Text("\(viewModel.quantity)")
                                    .font(.system(size: 20, weight: .bold))
                                    .frame(width: 50)
                                Button(action: { 
                                    let max = Int(Double(product.availableQuantity ?? "0") ?? 0)
                                    if viewModel.quantity < max { viewModel.quantity += 1 } 
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("총 상품 금액").font(.system(size: 18))
                            Spacer()
                            Text("\(CurrencyUtil.formatCurrency(viewModel.totalPrice))")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(16)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                    
                    
                    // 5. Sub Images
                    let subImages = productDetail.imageMetas.filter { $0.represent == 0 }
                    if !subImages.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("상품 이미지")
                                .font(.system(size: 19, weight: .bold))
                            
                            VStack(spacing: 16) {
                                ForEach(subImages, id: \.imageId) { img in
                                    KFImage(URL(string: img.imageUrl ?? ""))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 250)
                                        .cornerRadius(8)
                                        .clipped()
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }
                }
                .padding(16)
                
            } else {
                ProgressView("정보를 불러오는 중입니다...")
                    .frame(maxWidth: .infinity, minHeight: 300)
            }
        }
    }
    
    private func wrapHTML(_ description: String) -> String {
        let decoded = description
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
        
        return """
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                img { max-width: 100% !important; height: auto !important; }
                body { font-size: 18px; line-height: 1.6; word-wrap: break-word; margin: 0; padding: 0; }
            </style>
        </head>
        <body>
            \(decoded)
        </body>
        </html>
        """
    }
}

// ... StatusControlView omitted for brevity if it's the same ...

// MARK: - HTMLStringView
struct HTMLStringView: UIViewRepresentable {
    let htmlContent: String
    @Binding var height: CGFloat

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: HTMLStringView

        init(_ parent: HTMLStringView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] (result, error) in
                if let height = result as? CGFloat {
                    DispatchQueue.main.async {
                        self?.parent.height = height + 40 // Add some padding
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: URL(string: "about:blank"))
    }
}
