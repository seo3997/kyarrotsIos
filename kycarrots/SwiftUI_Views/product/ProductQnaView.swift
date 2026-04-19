//
//  ProductQnaView.swift
//  kycarrots
//
//  Created by soohyun on 03/21/26.
//

import SwiftUI

struct ProductQnaView: View {
    @ObservedObject var viewModel: ProductDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Fixed Header (Always visible)
            HStack(alignment: .center) {
                Text("상품 문의")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "1e293b"))
                
                Spacer()
                
                // Only for ROLE_PUB
                if LoginInfoUtil.getMemberCode() == Constants.ROLE_PUB {
                    Button(action: {
                        viewModel.startQnaWrite()
                    }) {
                        Text("문의 하기")
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
            VStack {
                VStack(alignment: .leading, spacing: 0) {
                    if viewModel.qnas.isEmpty {
                        VStack {
                            Spacer().frame(height: 100)
                            Text("등록된 문의가 없습니다.")
                                .foregroundColor(Color(hex: "94a3b8"))
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.qnas) { qna in
                                QnaRow(qna: qna, 
                                       currentUserId: viewModel.currentUserId,
                                       onEdit: { viewModel.editQna(qna) },
                                       onDelete: { viewModel.deleteQna(qna) })
                                Divider().padding(.horizontal, 24)
                            }
                        }
                    }
                }
                .padding(.bottom, 100) // Padding for fixed bottom bar
            }
        }
        .onAppear {
            viewModel.loadQnas()
        }
    }
}

struct QnaRow: View {
    let qna: QnaVo
    let currentUserId: String
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        let isSecret = qna.secretYn == "Y"
        let normalizedWriter = qna.userNo?.split(separator: ".").first ?? ""
        let normalizedMe = currentUserId.split(separator: ".").first ?? ""
        let isOwner = normalizedWriter == normalizedMe || normalizedMe == "admin"
        let canView = !isSecret || isOwner
        
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                // Status Badge
                Text(qna.qnaStatus == "2" ? "답변완료" : "답변대기")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(qna.qnaStatus == "2" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .foregroundColor(qna.qnaStatus == "2" ? .blue : .gray)
                    .cornerRadius(4)
                
                if isSecret {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Text(canView ? (qna.title ?? "") : "비밀글입니다.")
                    .font(.system(size: 15, weight: isSecret ? .medium : .bold))
                    .foregroundColor(canView ? .primary : .secondary)
                
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
            
            HStack {
                Text(qna.userNm ?? "익명")
                Text("|")
                Text(qna.registDt ?? "")
            }
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            
            if isExpanded && canView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(qna.contents ?? "")
                        .font(.system(size: 14))
                        .padding(.top, 4)
                    
                    if let answer = qna.answerContents, !answer.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.turn.down.right")
                                    .foregroundColor(.blue)
                                Text("판매자 답변")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            Text(answer)
                                .font(.system(size: 14))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .padding(24)
        .contentShape(Rectangle())
        .onTapGesture {
            if canView {
                withAnimation { isExpanded.toggle() }
            }
        }
    }
}
