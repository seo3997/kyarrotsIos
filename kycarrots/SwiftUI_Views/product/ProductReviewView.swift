//
//  ProductReviewView.swift
//  kycarrots
//
//  Created by soohyun on 03/21/26.
//

import SwiftUI
import Kingfisher

struct ProductReviewView: View {
    @ObservedObject var viewModel: ProductDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Fixed Header (Always visible)
            HStack(alignment: .center) {
                Text("상품 리뷰")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "1e293b"))
                
                Spacer()
                
                // Only for ROLE_PUB
                if LoginInfoUtil.getMemberCode() == Constants.ROLE_PUB {
                    Button(action: {
                        viewModel.startReviewWrite()
                    }) {
                        Text("리뷰 쓰기")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 12)
            
            Divider()
                .frame(height: 2)
                .background(Color(hex: "f1f5f9"))
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            // 2. Scrollable Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if viewModel.reviews.isEmpty {
                        VStack {
                            Spacer().frame(height: 100)
                            Text("등록된 리뷰가 없습니다.")
                                .foregroundColor(Color(hex: "94a3b8"))
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.reviews) { review in
                                ReviewRow(review: review, 
                                         currentUserId: viewModel.currentUserId,
                                         onEdit: { viewModel.editReview(review) },
                                         onDelete: { viewModel.deleteReview(review) })
                                Divider().padding(.horizontal, 24)
                            }
                        }
                    }
                }
                .padding(.bottom, 100) // Padding for fixed bottom bar
            }
        }
        .onAppear {
            viewModel.loadReviews()
        }
    }
}

struct ReviewRow: View {
    let review: ReviewVo
    let currentUserId: String
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        let normalizedWriter = review.userNo?.split(separator: ".").first ?? ""
        let normalizedMe = currentUserId.split(separator: ".").first ?? ""
        let isOwner = normalizedWriter == normalizedMe || normalizedMe == "admin"
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= review.rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(star <= review.rating ? .orange : .gray.opacity(0.3))
                    }
                }
                
                Spacer()
                
                if isOwner {
                    Menu {
                        Button("수정", action: onEdit)
                        Button("삭제", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.gray)
                            .padding(4)
                    }
                }
            }
            
            Text(review.contents ?? "")
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Review Images (80x80 thumbnails from comma-separated URLs)
            if let imgUrls = review.filePaths ?? review.fileRltvPath, !imgUrls.isEmpty {
                let urls = imgUrls.split(separator: ",").map(String.init)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(urls, id: \.self) { url in
                            KFImage(URL(string: url))
                                .retry(maxCount: 3, interval: .seconds(2))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .clipped()
                                .onTapGesture {
                                    // Image show logic bridge
                                }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            HStack {
                Text(review.userNm ?? "익명")
                Text("|")
                Text(review.registDt ?? "")
            }
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
        .padding(24)
        .background(Color(UIColor.systemBackground))
    }
}
