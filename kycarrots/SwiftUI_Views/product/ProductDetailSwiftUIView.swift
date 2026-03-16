import SwiftUI
import Kingfisher

struct ProductDetailSwiftUIView: View {
    @StateObject var viewModel: ProductDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Callbacks to UI
    var onEditProduct: (Int64) -> Void
    var onOpenChat: (ChatRoomResponse) -> Void
    var onShowBuyerSelection: ([ChatRoomResponse]) -> Void
    var onShowBuyerPickSheet: ([ChatBuyerDto], @escaping (ChatBuyerDto?) -> Void) -> Void
    var onAskRejectReason: (@escaping (String) -> Void) -> Void
    var onShowAlert: (String, String) -> Void
    
    @State private var showingStatusPicker = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background Color
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // 1. Header Image Area (Full Bleed)
                        headerImageOverlay(width: geometry.size.width)
                        
                        // 2. Content Area (Fixed Width with Padding)
                        VStack(alignment: .leading, spacing: 16) {
                            
                            // Product Title
                            titleSection
                            
                            // Reject Reason (Only if rejected)
                            if shouldShowRejectReason {
                                rejectReasonCard
                            }
                            
                            // Main Details Card (Price, Status, Info)
                            mainDetailsCard
                            
                            // Description Card
                            descriptionCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 120) // Bottom Spacing for FAB
                        .frame(width: geometry.size.width, alignment: .leading)
                    }
                }
                .edgesIgnoringSafeArea(.top)
                
                // FAB: Chat Button
                chatFloatingButton
                
                // Loading Overlay
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.fetchData()
        }
        .confirmationDialog("상태 변경", isPresented: $showingStatusPicker, titleVisibility: .visible) {
            statusPickerButtons
        }
    }
    
    // MARK: - Subviews
    
    private func headerImageOverlay(width: CGFloat) -> some View {
        ZStack(alignment: .top) {
            // Main Image
            Group {
                if let mainImageUrl = viewModel.productDetail?.imageMetas.first(where: { $0.represent == 1 })?.imageUrl {
                    KFImage(URL(string: mainImageUrl))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: 300)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: width, height: 300)
                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                }
            }
            
            // Header Buttons (Back, Edit, Favorite)
            HStack {
                // Back Button
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Edit Button (Seller only)
                    if canEditProduct {
                        Button(action: { onEditProduct(viewModel.productId) }) {
                            Text("수정")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(20)
                                .shadow(radius: 2)
                        }
                    }
                    
                    // Favorite Toggle (Buyer only)
                    if canFavoriteProduct {
                        Button(action: { viewModel.toggleFavorite() }) {
                            Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 20))
                                .foregroundColor(viewModel.isFavorite ? .red : .gray)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                    }
                }
            }
            .padding(.top, 60)
            .padding(.horizontal, 16)
        }
    }
    
    private var titleSection: some View {
        Text(viewModel.productDetail?.product.title ?? "-")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.primary)
            .lineLimit(2)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var shouldShowRejectReason: Bool {
        guard let p = viewModel.productDetail?.product else { return false }
        return !(p.rejectReason ?? "").isEmpty && p.saleStatus == "98"
    }
    
    private var rejectReasonCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("반려 사유")
                    .font(.headline)
            }
            .foregroundColor(.red)
            
            Text(viewModel.productDetail?.product.rejectReason ?? "")
                .font(.subheadline)
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 1.0, green: 0.97, blue: 0.97))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 1))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var mainDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                // Price
                Text("가격:\(formatPrice(viewModel.productDetail?.product.price ?? 0))원")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.blue)
                
                Spacer()
                
                // Status Change Button
                if !viewModel.statusOptions.isEmpty {
                    Button(action: { showingStatusPicker = true }) {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedStatus?.strMsg ?? "상태 변경")
                                .font(.system(size: 13, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        .foregroundColor(.primary)
                    }
                } else if let currentStatus = viewModel.productDetail?.product.saleStatus {
                    Text("상태: \(currentStatus)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Detailed Info Grid-like VStack
            VStack(spacing: 12) {
                infoRow(title: "희망출하일:", value: viewModel.productDetail?.product.desiredShippingDate ?? "-")
                infoRow(title: "수량:", value: "\(formatComma(viewModel.productDetail?.product.quantity ?? 0))\(viewModel.productDetail?.product.unitCodeNm ?? "")")
                infoRow(title: "카테고리:", value: categoryString)
                infoRow(title: "지역:", value: areaString)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("상품 설명")
                .font(.system(size: 17, weight: .bold))
            
            Text(viewModel.productDetail?.product.description ?? "상품 설명이 없습니다.")
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            subImagesScrollView
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var subImagesScrollView: some View {
        let subImages = viewModel.productDetail?.imageMetas.filter { $0.represent == 0 }.compactMap { $0.imageUrl } ?? []
        return Group {
            if !subImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(subImages, id: \.self) { url in
                            KFImage(URL(string: url))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .cornerRadius(8)
                                .clipped()
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var chatFloatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: handleChatTap) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.green)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2).edgesIgnoringSafeArea(.all)
            ProgressView().scaleEffect(1.5)
        }
    }
    
    private var statusPickerButtons: some View {
        Group {
            ForEach(viewModel.statusOptions, id: \.strIdx) { option in
                Button(option.strMsg ?? "-") {
                    handleStatusChange(option: option)
                }
            }
            Button("취소", role: .cancel) {}
        }
    }
    
    // MARK: - Logic & Helpers
    
    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 85, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
    
    private var canEditProduct: Bool {
        guard let p = viewModel.productDetail?.product else { return false }
        let isSeller = LoginInfoUtil.getMemberCode() == Constants.ROLE_SELL
        let isOwner = p.userId == LoginInfoUtil.getUserId() || p.wholesalerId == LoginInfoUtil.getUserId()
        return isSeller && isOwner
    }
    
    private var canFavoriteProduct: Bool {
        LoginInfoUtil.getMemberCode() == Constants.ROLE_PUB
    }
    
    private var categoryString: String {
        [viewModel.productDetail?.product.categoryMidNm ?? "",
         viewModel.productDetail?.product.categorySclsNm ?? ""]
            .filter { !$0.isEmpty }
            .joined(separator: " > ")
    }
    
    private var areaString: String {
        [viewModel.productDetail?.product.areaMidNm ?? "",
         viewModel.productDetail?.product.areaSclsNm ?? ""]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    private func handleStatusChange(option: TxtListDataInfo) {
        let code = option.strIdx ?? ""
        let label = option.strMsg ?? ""
        if code == "99" {
            Task {
                let buyers = await viewModel.getChatBuyers()
                if buyers.isEmpty {
                    confirmStatusChange(label: label, code: code)
                } else {
                    onShowBuyerPickSheet(buyers) { pickedBuyer in
                        confirmStatusChange(label: label, code: code, buyer: pickedBuyer)
                    }
                }
            }
        } else if viewModel.productDetail?.product.saleStatus == "0" && code == "98" {
            onAskRejectReason { reason in
                confirmStatusChange(label: label, code: code, rejectReason: reason)
            }
        } else {
            confirmStatusChange(label: label, code: code)
        }
    }
    
    private func confirmStatusChange(label: String, code: String, rejectReason: String? = nil, buyer: ChatBuyerDto? = nil) {
        Task {
            let success = await viewModel.updateStatus(code: code, rejectReason: rejectReason, buyer: buyer)
            if success { onShowAlert("완료", "상태가 변경되었습니다.") }
            else { onShowAlert("오류", "상태 변경 실패") }
        }
    }
    
    private func handleChatTap() {
        let systemType = Constants.SYSTEM_TYPE
        let memberCode = LoginInfoUtil.getMemberCode()
        if systemType == 1 { handleChatSystemType1(memberCode: memberCode) }
        else { handleChatSystemType2(memberCode: memberCode) }
    }
    
    private func handleChatSystemType1(memberCode: String) {
        let isBuyer = (memberCode == Constants.ROLE_PUB)
        if isBuyer {
            Task { if let room = await viewModel.createOrGetChatRoom() { onOpenChat(room) } }
        } else {
            Task {
                let rooms = await viewModel.getUserChatRooms()
                if rooms.isEmpty { onShowAlert("안내", "이 상품에 대한 채팅 요청이 없습니다") }
                else if rooms.count == 1, let room = rooms.first { onOpenChat(room) }
                else { onShowBuyerSelection(rooms) }
            }
        }
    }
    
    private func handleChatSystemType2(memberCode: String) {
        if memberCode == Constants.ROLE_PUB || memberCode == Constants.ROLE_SELL || memberCode == Constants.ROLE_PROJ {
            handleChatSystemType1(memberCode: memberCode)
        }
    }
    
    private func formatPrice(_ price: Any?) -> String {
        let val: Double
        if let p = price as? Double { val = p }
        else if let p = price as? Int { val = Double(p) }
        else if let p = price as? Int64 { val = Double(p) }
        else if let p = price as? String { val = Double(p) ?? 0 }
        else { return "-" }
        return formatCommaNoDecimal(val)
    }
    
    private func formatCommaNoDecimal(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "0"
    }

    private func formatComma(_ value: Any?) -> String {
        let d: Double
        if let p = value as? Double { d = p }
        else if let p = value as? Int { d = Double(p) }
        else if let p = value as? Int64 { d = Double(p) }
        else if let p = value as? String { d = Double(p) ?? 0 }
        else { d = 0 }
        return formatCommaNoDecimal(d)
    }
}
