//
//  ProductQnaView.swift
//  kycarrots
//

import SwiftUI

struct ProductQnaView: View {
    @ObservedObject var viewModel: ProductDetailViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.qnas.isEmpty {
                VStack {
                    Spacer().frame(height: 100)
                    Text("등록된 문의가 없습니다.")
                        .foregroundColor(.gray)
                }
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.qnas) { qna in
                        QnaRowView(qna: qna, currentUserId: UserDefaults.standard.string(forKey: "userNo"))
                        Divider()
                    }
                }
                .padding(.top)
            }
        }
        .onAppear {
            viewModel.loadQnas()
        }
    }
}

struct QnaRowView: View {
    let qna: QnaVo
    let currentUserId: String?
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                // Status Badge
                StatusBadge(status: qna.qnaStatus ?? "10", hasAnswer: qna.answerContents != nil)
                
                Text(qna.title ?? "")
                    .font(.body)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                if qna.secretYn == "Y" {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(qna.registDt ?? "")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .onTapGesture {
                if canSeeContents {
                    withAnimation { isExpanded.toggle() }
                }
            }
            
            Text("\(qna.userNm ?? "사용자")")
                .font(.footnote)
                .foregroundColor(.gray)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(qna.contents ?? "")
                        .font(.body)
                        .padding(.vertical, 8)
                    
                    if let answer = qna.answerContents {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("공식 답변")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                            Text(answer)
                                .font(.body)
                            Text(qna.answeredAt ?? "")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.top, 4)
            } else if !canSeeContents {
                Text("비밀글입니다.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
    }
    
    private var canSeeContents: Bool {
        return qna.secretYn != "Y" || (currentUserId != nil && currentUserId == qna.userNo)
    }
}

struct StatusBadge: View {
    let status: String
    let hasAnswer: Bool
    
    var body: some View {
        Text(hasAnswer || status == "20" ? "답변완료" : "접수")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(hasAnswer || status == "20" ? .green : .gray)
            .background((hasAnswer || status == "20" ? Color.green : Color.gray).opacity(0.1))
            .cornerRadius(4)
    }
}
