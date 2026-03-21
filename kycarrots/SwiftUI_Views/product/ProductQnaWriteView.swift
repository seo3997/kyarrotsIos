//
//  ProductQnaWriteView.swift
//  kycarrots
//
//  Created by soohyun on 03/21/26.
//

import SwiftUI

struct ProductQnaWriteView: View {
    @ObservedObject var viewModel: ProductDetailViewModel
    var qna: QnaVo? // nil for new QnA
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var contents: String = ""
    @State private var isSecret: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 1. Title Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("문의 제목")
                                .font(.system(size: 16, weight: .bold))
                            
                            TextField("제목을 입력해주세요.", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.vertical, 4)
                        }
                        .padding([.horizontal, .top], 24)
                        
                        // 2. Content Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("문의 내용")
                                .font(.system(size: 16, weight: .bold))
                            
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $contents)
                                    .frame(height: 200)
                                    .padding(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                
                                if contents.isEmpty {
                                    Text("구매하시려는 상품에 대해 궁금한 점을 남겨주세요.")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // 3. Secret Option
                        Toggle(isOn: $isSecret) {
                            HStack(spacing: 8) {
                                Image(systemName: isSecret ? "lock.fill" : "lock.open.fill")
                                    .foregroundColor(isSecret ? .blue : .gray)
                                Text("비밀글로 문의하기")
                                    .font(.system(size: 15))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        
                        Text("• 수집된 문의 내용은 상품 상세 페이지 하단에 노출됩니다.\n• 개인정보(연락처, 계좌번호 등)가 포함되지 않도록 주의해 주세요.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                    }
                }
                
                // Submit Button
                Button(action: {
                    viewModel.submitQna(
                        qnaId: qna?.qnaId,
                        title: title,
                        contents: contents,
                        secretYn: isSecret ? "Y" : "N"
                    )
                }) {
                    Text(qna != nil ? "문의 수정하기" : "문의 등록하기")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isButtonEnabled ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isButtonEnabled || viewModel.isLoading)
                .padding(24)
                .background(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
            }
            .navigationTitle(qna != nil ? "문의 수정" : "문의 작성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
            }
            .onAppear {
                if let q = qna {
                    title = q.title ?? ""
                    contents = q.contents ?? ""
                    isSecret = q.secretYn == "Y"
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
    
    private var isButtonEnabled: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !contents.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
