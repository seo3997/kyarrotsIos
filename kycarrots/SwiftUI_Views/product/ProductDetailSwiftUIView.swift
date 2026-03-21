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
            
            // 2. Main Image Section
            if let detail = viewModel.productDetail {
                let mainImg = detail.imageMetas.first(where: { $0.represent == 1 }) ?? detail.imageMetas.first
                KFImage(URL(string: mainImg?.imageUrl ?? ""))
                    .resizable()
                    .placeholder {
                        Rectangle().fill(Color.gray.opacity(0.1))
                            .overlay(ProgressView())
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .clipped()
            }
            
            // 3. Tab Bar Section
            HStack(spacing: 0) {
                ForEach(["상품설명", "상품리뷰", "상품문의"].enumerated().map({$0}), id: \.offset) { index, title in
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 15, weight: viewModel.selectedTab == index ? .bold : .medium))
                            .foregroundColor(viewModel.selectedTab == index ? .primary : .secondary)
                        
                        // Underline
                        Rectangle()
                            .fill(viewModel.selectedTab == index ? Color.accentColor : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            viewModel.selectedTab = index
                        }
                    }
                }
            }
            .padding(.top, 8)
            .background(Color(UIColor.systemBackground))
            
            Divider()

            // Tab Content
            ZStack(alignment: .bottom) {
                // Main Content Area
                VStack(spacing: 0) {
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
                .frame(maxHeight: .infinity)
                
                // Fixed Bottom Action Bar (L276 style)
                if let product = viewModel.productDetail?.product {
                    VStack(spacing: 0) {
                        Divider()
                        HStack(spacing: 12) {
                            // Favorite
                            Button(action: { viewModel.toggleFavorite() }) {
                                Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 24))
                                    .foregroundColor(viewModel.isFavorite ? .red : .gray)
                                    .padding(12)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                            }
                            
                            // Chat
                            Button(action: { 
                                NotificationCenter.default.post(name: NSNotification.Name("OpenChatRequested"), object: nil)
                            }) {
                                Text("채팅하기")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                            }
                            
                            // Buy Button
                            Button(action: { /* Buy logic */ }) {
                                Text("구매하기")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 4)
                            }
                        }
                        .padding(16)
                        .background(Color(UIColor.systemBackground))
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.fetchData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenChatRequested"))) { _ in
            handleChatTap()
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
