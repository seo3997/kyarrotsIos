//
//  ProductReviewWriteView.swift
//  kycarrots
//
//  Created by soohyun on 03/21/26.
//

import SwiftUI
import PhotosUI

struct ProductReviewWriteView: View {
    @ObservedObject var viewModel: ProductDetailViewModel
    var review: ReviewVo? // nil for new review
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var rating: Int = 5
    @State private var contents: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImagesData: [Data] = []
    
    // For editing existing images (Simplified: We don't edit existing ones via multipart here, usually replace)
    @State private var existingPaths: [String] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 1. Rating Section
                        VStack(alignment: .center, spacing: 12) {
                            Text("상품은 어떠셨나요?")
                                .font(.system(size: 18, weight: .bold))
                            
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { index in
                                    Image(systemName: index <= rating ? "star.fill" : "star")
                                        .font(.system(size: 36))
                                        .foregroundColor(index <= rating ? .yellow : .gray.opacity(0.3))
                                        .onTapGesture {
                                            rating = index
                                        }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                        
                        Divider()
                        
                        // 2. Content Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("리뷰 내용")
                                .font(.system(size: 16, weight: .bold))
                            
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $contents)
                                    .frame(height: 150)
                                    .padding(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                
                                if contents.isEmpty {
                                    Text("상품 서비스에 대한 솔직한 리뷰를 남겨주세요.")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // 3. Image Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("사진 첨부 (최대 3장)")
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                                Text("\(selectedImagesData.count)/3")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 12) {
                                // Photos Picker Button
                                PhotosPicker(selection: $selectedItems, maxSelectionCount: 3, matching: .images) {
                                    VStack {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 24))
                                        Text("사진 추가")
                                            .font(.system(size: 12))
                                    }
                                    .frame(width: 80, height: 80)
                                    .background(Color.gray.opacity(0.05))
                                    .foregroundColor(.gray)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .onChange(of: selectedItems) { _ in
                                    loadImages()
                                }
                                
                                // Preview List
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(0..<selectedImagesData.count, id: \.self) { index in
                                            ZStack(alignment: .topTrailing) {
                                                if let uiImage = UIImage(data: selectedImagesData[index]) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 80, height: 80)
                                                        .cornerRadius(8)
                                                        .clipped()
                                                }
                                                
                                                Button(action: {
                                                    selectedImagesData.remove(at: index)
                                                    selectedItems.remove(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                                }
                                                .padding(4)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        if review != nil && !existingPaths.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("기존 사진")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(existingPaths, id: \.self) { path in
                                            AsyncImage(url: URL(string: path)) { img in
                                                img.resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Color.gray.opacity(0.1)
                                            }
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(4)
                                            .clipped()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                // Submit Button
                Button(action: {
                    viewModel.submitReview(
                        reviewId: review?.reviewId,
                        rating: rating,
                        contents: contents,
                        images: selectedImagesData.isEmpty ? nil : selectedImagesData
                    )
                }) {
                    Text(review != nil ? "리뷰 수정하기" : "리뷰 등록하기")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(contents.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(contents.isEmpty || viewModel.isLoading)
                .padding(24)
                .background(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
            }
            .navigationTitle(review != nil ? "리뷰 수정" : "리뷰 작성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
            }
            .onAppear {
                if let r = review {
                    rating = r.rating
                    contents = r.contents ?? ""
                    if let paths = r.filePaths ?? r.fileRltvPath {
                        existingPaths = paths.split(separator: ",").map(String.init)
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                        ProgressView("저장 중...")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    .ignoresSafeArea()
                }
            }
        }
    }
    
    private func loadImages() {
        Task {
            var dataList: [Data] = []
            for item in selectedItems {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    dataList.append(data)
                }
            }
            await MainActor.run {
                self.selectedImagesData = dataList
            }
        }
    }
}
