//
//  ProductDescriptionView.swift
//  kycarrots
//

import SwiftUI
import WebKit
import Kingfisher

struct ProductDescriptionView: View {
    @ObservedObject var viewModel: ProductDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Main Image
            if let firstImg = viewModel.productDetail?.product.imageUrl {
                KFImage(URL(string: firstImg))
                    .resizable()
                    .placeholder {
                        ProgressView()
                    }
                    .onFailure { _ in
                        Image(systemName: "photo").foregroundColor(.gray)
                    }
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .clipped()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Title and Basic Info
                Text(viewModel.productDetail?.product.title ?? "")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    Text("\(viewModel.productDetail?.product.categoryMidNm ?? "") > \(viewModel.productDetail?.product.categorySclsNm ?? "")")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(viewModel.productDetail?.product.areaMidNm ?? "") \(viewModel.productDetail?.product.areaSclsNm ?? "")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Divider().padding(.vertical, 8)
                
                // Price and Quantity calculation logic (simplified for now)
                HStack {
                    Text("판매가")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(CurrencyUtil.formatCurrency(Int(viewModel.productDetail?.product.price ?? "0") ?? 0))")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    Text(" / \(viewModel.productDetail?.product.unitCodeNm ?? "")")
                        .font(.subheadline)
                }
                
                // Quantity Selector
                HStack {
                    Text("수량")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    HStack(spacing: 16) {
                        Button(action: {
                            if viewModel.quantity > 1 { viewModel.quantity -= 1 }
                        }) {
                            Image(systemName: "minus.circle")
                                .font(.title2)
                                .foregroundColor(viewModel.quantity > 1 ? .primary : .gray)
                        }
                        
                        Text("\(viewModel.quantity)")
                            .font(.headline)
                            .frame(width: 40)
                        
                        Button(action: {
                            viewModel.quantity += 1
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.top, 8)
                
                Divider().padding(.vertical, 8)
                
                // Total Price
                HStack {
                    Text("총 상품금액")
                        .font(.headline)
                    Spacer()
                    Text("\(CurrencyUtil.formatCurrency(viewModel.totalPrice))")
                        .font(.title3)
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
                
                Divider().padding(.vertical, 16)
                
                // HTML Content / Description
                if let html = viewModel.productDetail?.product.description {
                    HTMLStringView(htmlContent: html)
                        .frame(maxWidth: .infinity)
                        .frame(height: 400) // This might need dynamic height
                }
            }
            .padding()
        }
    }
}

struct HTMLStringView: UIViewRepresentable {
    let htmlContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let styledHTML = "<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></header><body>\(htmlContent)</body>"
        uiView.loadHTMLString(styledHTML, baseURL: nil)
    }
}
