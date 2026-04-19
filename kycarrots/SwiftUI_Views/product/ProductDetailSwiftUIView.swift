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
        ZStack(alignment: .top) {
            // Main Scrollable Content
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    // 1. Parallax Image Section
                    if let detail = viewModel.productDetail {
                        let mainImg = detail.imageMetas.first(where: { $0.represent == 1 }) ?? detail.imageMetas.first
                        
                        GeometryReader { geo in
                            let minY = geo.frame(in: .global).minY
                            let height = 450 + (minY > 0 ? minY : 0)
                            
                            KFImage(URL(string: mainImg?.imageUrl ?? ""))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: height)
                                .offset(y: minY > 0 ? -minY : 0)
                                .clipped()
                        }
                        .frame(height: 450)
                        
                        // 2. Product Title & Info
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                Text(detail.product.title)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                
                                Spacer()
                                
                                StatusControlView(viewModel: viewModel, product: detail.product)
                            }
                        }
                        .padding(24)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(24, corners: [.topLeft, .topRight])
                        .offset(y: -30)
                    }
                    
                    // 3. Sticky Tab Bar Section
                    Section(header: 
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                ForEach(["상품설명", "상품리뷰", "상품문의"].enumerated().map({$0}), id: \.offset) { index, title in
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            viewModel.selectedTab = index
                                        }
                                    }) {
                                        VStack(spacing: 12) {
                                            Text(title)
                                                .font(.system(size: 16, weight: viewModel.selectedTab == index ? .bold : .medium))
                                                .foregroundColor(viewModel.selectedTab == index ? .primary : .secondary)
                                            
                                            Rectangle()
                                                .fill(viewModel.selectedTab == index ? Color.accentColor : Color.clear)
                                                .frame(height: 3)
                                                .padding(.horizontal, 8)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.top, 8)
                            .background(Color(UIColor.systemBackground))
                            
                            Divider()
                        }
                        .offset(y: -31)
                    ) {
                        // 4. Tab Content
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
                        .padding(.bottom, 120)
                        .offset(y: -31)
                        .background(Color(UIColor.systemBackground))
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // 5. Fixed Navigation Header (Top Bar)
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        AppCoordinator.shared?.popBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                            .padding(8)
                    }
                    
                    Spacer()
                    
                    Text("상품정보")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if canEditProduct {
                        Button(action: { onEditProduct(viewModel.productId) }) {
                            Text("수정")
                                .font(.subheadline.bold())
                                .foregroundColor(.accentColor)
                        }
                    } else {
                        Spacer().frame(width: 44)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                
                Divider()
            }
            .padding(.top, 44) // Adjust for status bar
            .ignoresSafeArea(edges: .top)
            
            // 6. Fixed Bottom Action Bar
            VStack(spacing: 0) {
                Spacer()
                if let product = viewModel.productDetail?.product {
                    VStack(spacing: 0) {
                        Divider()
                        HStack(spacing: 12) {
                            if isBuyer {
                                Button(action: { viewModel.toggleFavorite() }) {
                                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                                        .font(.system(size: 24))
                                        .foregroundColor(viewModel.isFavorite ? .red : .gray)
                                        .padding(12)
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(12)
                                }
                            }
                            
                            Button(action: { 
                                NotificationCenter.default.post(name: NSNotification.Name("OpenChatRequested"), object: nil)
                            }) {
                                Text("채팅하기")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(12)
                            }
                            
                            if isBuyer {
                                NavigationLink(destination: OrderCheckoutView(
                                    viewModel: OrderCheckoutViewModel(
                                        product: product,
                                        quantity: 1,
                                        selectedOption: nil,
                                        productImageUrl: viewModel.productDetail?.imageMetas.first(where: { $0.represent == 1 })?.imageUrl ?? viewModel.productDetail?.imageMetas.first?.imageUrl
                                    )
                                )) {
                                    Text("구매하기")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 54)
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                        .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 6)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                        .background(Color(UIColor.systemBackground).shadow(radius: 10, y: -5))
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarHidden(true)
        .sheet(item: $viewModel.activeSheet) { sheetType in
            switch sheetType {
            case .reviewWrite(let r):
                ProductReviewWriteView(viewModel: viewModel, review: r)
            case .qnaWrite(let q):
                ProductQnaWriteView(viewModel: viewModel, qna: q)
            }
        }
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
        .sheet(isPresented: $viewModel.showRoomSelectionSheet) {
            NavigationView {
                List(viewModel.roomsForSelection, id: \.id) { room in
                    Button(action: {
                        viewModel.showRoomSelectionSheet = false
                        onOpenChat(room)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("구매자: \(room.buyerId)")
                                    .fontWeight(.bold)
                                if let date = room.createdAt {
                                    Text("생성일: \(date)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("채팅 대상 선택")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("닫기") { viewModel.showRoomSelectionSheet = false }
                    }
                }
            }
        }
        .confirmationDialog("채팅 채널 선택", isPresented: $viewModel.showChatBuyerSelection, titleVisibility: .visible) {
            Button("구매자에게 채팅") {
                Task {
                    let rooms = await viewModel.getUserChatRooms(branchId: LoginInfoUtil.getBranchId())
                    if rooms.isEmpty { onShowAlert("안내", "채팅 요청이 없습니다") }
                    else if rooms.count == 1, let room = rooms.first {
                        onOpenChat(room)
                    }
                    else { 
                        viewModel.roomsForSelection = rooms
                        viewModel.showRoomSelectionSheet = true
                    }
                }
            }
            Button("본사와 채팅") {
                Task {
                    let myBranchId = LoginInfoUtil.getBranchId()
                    let centerId = Constants.CENTER_BRANCH_ID
                    if let room = await viewModel.createOrGetChatRoom(buyerId: myBranchId, branchId: centerId) {
                        onOpenChat(room)
                    }
                }
            }
            Button("취소", role: .cancel) { }
        }
    }
    
    // MARK: - Logic Helpers
    
    private var canEditProduct: Bool {
        guard let p = viewModel.productDetail?.product else { return false }
        let isSeller = LoginInfoUtil.getMemberCode() == Constants.ROLE_SELL
        let isOwner = p.userId == LoginInfoUtil.getUserId() || p.wholesalerId == LoginInfoUtil.getUserId()
        return isSeller && isOwner
    }
    
    private var isBuyer: Bool {
        return LoginInfoUtil.getMemberCode() == Constants.ROLE_PUB
    }
    
    private func handleChatTap() {
        let memberCode = LoginInfoUtil.getMemberCode()
        let myId = LoginInfoUtil.getUserId()
        let myBranchId = LoginInfoUtil.getBranchId()
        let centerBranchId = Constants.CENTER_BRANCH_ID
        let pid = String(viewModel.productId)

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
                else { 
                    await MainActor.run {
                        viewModel.roomsForSelection = rooms
                        viewModel.showRoomSelectionSheet = true
                    }
                }
            }
        case Constants.ROLE_PROJ:
            // Match Android logic: "구매자에게 채팅" vs "본사와 채팅"
            viewModel.showChatBuyerSelection = true
        default:
            break
        }
    }
}

struct StatusControlView: View {
    @ObservedObject var viewModel: ProductDetailViewModel
    var product: ProductVo
    
    var body: some View {
        if viewModel.isBuyer {
            Text(product.saleStatusNm ?? "판매중")
                .font(.system(size: 15, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(6)
        } else {
            Menu {
                ForEach(viewModel.statusOptions, id: \.strIdx) { option in
                    Button(option.strMsg) {
                        viewModel.updateProductStatus(selectedCode: option.strIdx)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.selectedStatus?.strMsg ?? product.saleStatusNm ?? "상태 설정")
                    Image(systemName: "chevron.down").font(.system(size: 10))
                }
                .font(.system(size: 15, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(6)
            }
        }
    }
}

// MARK: - Extensions for UI
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
