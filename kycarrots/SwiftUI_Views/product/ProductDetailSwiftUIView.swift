//
//  ProductDetailSwiftUIView.swift
//  kycarrots
//

import SwiftUI
import Kingfisher

struct ProductDetailSwiftUIView: View {
    @StateObject var viewModel: ProductDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Callbacks to Coordinator
    var onEditProduct: (Int64) -> Void
    var onOpenChat: (ChatRoomResponse) -> Void
    var onShowBuyerSelection: ([ChatRoomResponse]) -> Void
    var onShowBuyerPickSheet: ([ChatBuyerDto], @escaping (ChatBuyerDto?) -> Void) -> Void
    var onAskRejectReason: (@escaping (String) -> Void) -> Void
    var onShowAlert: (String, String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                Spacer()
                Text("상품정보")
                    .font(.headline)
                Spacer()
                if canEditProduct {
                    Button(action: { onEditProduct(viewModel.productId) }) {
                        Text("수정")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // Tab Picker
                    Picker("", selection: $viewModel.selectedTab) {
                        Text("상품설명").tag(0)
                        Text("상품리뷰").tag(1)
                        Text("상품문의").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // Tab Content
                    switch viewModel.selectedTab {
                    case 0:
                        ProductDescriptionView(viewModel: viewModel)
                    case 1:
                        ProductReviewView(viewModel: viewModel)
                    case 2:
                        ProductQnaView(viewModel: viewModel)
                    default:
                        EmptyView()
                    }
                }
            }
            
            // Bottom Bar
            BottomActionBar(
                viewModel: viewModel,
                onChat: handleChatTap,
                onBuy: { /* Buy logic */ }
            )
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.fetchData()
        }
        .alert("알림", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Logic Helpers
    
    private var canEditProduct: Bool {
        guard let p = viewModel.productDetail?.product else { return false }
        let isSeller = LoginInfoUtil.getMemberCode() == Constants.ROLE_SELL
        let isOwner = p.userId == LoginInfoUtil.getUserId() || p.wholesalerId == LoginInfoUtil.getUserId()
        return isSeller && isOwner
    }
    
    private func handleChatTap() {
        let memberCode = LoginInfoUtil.getMemberCode()
        let myId = LoginInfoUtil.getUserId()
        let myBranchId = LoginInfoUtil.getBranchId()
        let centerBranchId = Constants.CENTER_BRANCH_ID

        switch memberCode {
        case Constants.ROLE_PUB:
            Task {
                if let room = await viewModel.createOrGetChatRoom(buyerId: myId, branchId: myBranchId) {
                    onOpenChat(room)
                }
            }
        case Constants.ROLE_SELL:
            Task {
                let rooms = await viewModel.getUserChatRooms(branchId: centerBranchId)
                if rooms.isEmpty { onShowAlert("안내", "채팅 요청이 없습니다") }
                else if rooms.count == 1, let room = rooms.first { onOpenChat(room) }
                else { onShowBuyerSelection(rooms) }
            }
        case Constants.ROLE_PROJ:
            // For branch, we might need a picker like in original view
            // Simplified for now to match the new structure
            onShowAlert("안내", "채팅 대상 선택 로직은 추후 보강 예정입니다.")
        default:
            break
        }
    }
}

struct BottomActionBar: View {
    @ObservedObject var viewModel: ProductDetailViewModel
    var onChat: () -> Void
    var onBuy: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 16) {
                // Favorite
                Button(action: {
                    viewModel.toggleFavorite()
                }) {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isFavorite ? .red : .gray)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                
                // Chat
                Button(action: onChat) {
                    Text("채팅하기")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Buy
                Button(action: onBuy) {
                    Text("구매하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
        }
    }
}
