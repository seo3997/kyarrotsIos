//
//  ProductReviewView.swift
//  kycarrots
//

import SwiftUI
import Kingfisher

struct ProductReviewView: View {
    @ObservedObject var viewModel: ProductDetailViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.reviews.isEmpty {
                VStack {
                    Spacer().frame(height: 100)
                    Text("등록된 리뷰가 없습니다.")
                        .foregroundColor(.gray)
                }
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.reviews) { review in
                        ReviewRowView(review: review)
                        Divider()
                    }
                }
                .padding(.top)
            }
        }
        .onAppear {
            viewModel.loadReviews()
        }
    }
}

struct ReviewRowView: View {
    let review: ReviewVo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Star Rating
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < review.rating ? "star.fill" : "star")
                            .foregroundColor(index < review.rating ? .yellow : .gray)
                            .font(.caption)
                    }
                }
                Spacer()
                Text(review.registDt ?? "")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text("\(review.userNm ?? "사용자")")
                .font(.footnote)
                .fontWeight(.bold)
            
            Text(review.contents ?? "")
                .font(.body)
                .padding(.vertical, 4)
            
            // Images (Horizontal Scroll)
            if let filePaths = review.fileRltvPath, !filePaths.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        let paths = filePaths.components(separatedBy: ",")
                        ForEach(paths, id: \.self) { path in
                            KFImage(URL(string: path.trimmingCharacters(in: .whitespaces)))
                                .resizable()
                                .placeholder { Color.gray.opacity(0.1) }
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .clipped()
                        }
                    }
                }
            }
        }
        .padding()
    }
}
