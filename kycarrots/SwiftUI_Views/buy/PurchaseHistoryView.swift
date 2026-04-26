import SwiftUI
import Kingfisher

struct PurchaseHistoryView: View {
    @StateObject private var viewModel = PurchaseHistoryViewModel()
    var onSelectOrder: ((String) -> Void)? = nil
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if viewModel.items.isEmpty && !viewModel.isLoading {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "cart.badge.minus")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("구매내역이 없습니다.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.items, id: \.id) { item in
                            PurchaseItemRow(
                                item: item,
                                onCancel: { viewModel.cancelOrder(item: item) },
                                onReturn: { viewModel.requestReturn(item: item) }
                            )
                            .padding(.bottom, 12) // Explicit spacing between cards
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let orderId = item.orderId {
                                    onSelectOrder?(orderId)
                                }
                            }
                            .onAppear {
                                if item.productId == viewModel.items.last?.productId {
                                    viewModel.fetchPurchaseList()
                                }
                            }
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        }
                    }
                }
                .refreshable {
                    viewModel.fetchPurchaseList(isRefresh: true)
                }
            }
        }
        .onAppear {
            if viewModel.items.isEmpty {
                viewModel.fetchPurchaseList(isRefresh: true)
            }
        }
        .alert("알림", isPresented: $viewModel.actionSuccess) {
            Button("확인") { viewModel.actionSuccess = false }
        } message: {
            Text(viewModel.successMessage ?? "처리가 완료되었습니다.")
        }
        .alert("알림", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
            Button("확인") { }
        } message: {
            if let msg = viewModel.errorMessage { Text(msg) }
        }
    }
}

struct PurchaseItemRow: View {
    let item: AdItem
    var onCancel: (() -> Void)?
    var onReturn: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Order No (Top Header)
            if let orderNo = item.orderNo {
                HStack {
                    Text("주문번호: \(orderNo)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 4)
            }
            
            HStack(alignment: .top, spacing: 12) {
                // Thumbnail Image
                if let urlString = item.imageUrl, let url = URL(string: urlString) {
                    KFImage(url)
                        .placeholder {
                            Rectangle()
                                .fill(Color(.systemGray6))
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title
                    Text(item.title ?? "제목 없음")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(.label))
                        .lineLimit(2)

                    // Price
                    if let priceString = item.price, let priceVal = Double(priceString) {
                        Text("\(formattedPrice(priceVal))원")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(red: 255/255, green: 109/255, blue: 0/255))
                    }
                }
                
                Spacer()
            }
            .padding(10)
            
            // Delivery Info
            if item.paymentStatus == "60", let tracking = item.trackingNo {
                HStack {
                    Text("택배사: \(item.deliveryCompanyNm ?? "-") | 송장번호: \(tracking)")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            
            // Status & Action Buttons
            Divider()
            HStack(spacing: 8) {
                // Status Badge (Bottom Left)
                if let statusText = getStatusName() {
                    statusBadgeView(text: statusText, status: item.paymentStatus ?? "")
                }
                
                Spacer()
                
                if showCancelButton() {
                    Button(action: {
                        onCancel?()
                    }) {
                        Text("주문 취소")
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .foregroundColor(.red)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                }
                if showReturnButton() {
                    Button(action: {
                        onReturn?()
                    }) {
                        Text("반품 요청")
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .foregroundColor(.gray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(10)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func statusBadgeView(text: String, status: String) -> some View {
        let isInactive = status == "40" // 취소
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(isInactive ? Color(.systemGray6) : Color(.systemBlue).opacity(0.1))
            .foregroundColor(isInactive ? .gray : .blue)
            .cornerRadius(4)
    }
    
    private func getStatusName() -> String? {
        if let nm = item.orderStatusNm, !nm.isEmpty { return nm }
        guard let status = item.paymentStatus else { return nil }
        
        switch status {
        case "10", "READY": return "결제대기"
        case "20", "FAILED": return "결제실패"
        case "30", "PAID": return "결제완료"
        case "40", "CANCEL": return "주문취소"
        case "50", "PREPARING": return "배송준비중"
        case "60", "SHIPPING": return "배송중"
        case "70", "DELIVERED": return "배송완료"
        case "80", "RETURN_REQUESTED": return "반품요청"
        case "89", "RETURN_COMPLETED": return "반품완료"
        case "99", "CONFIRM": return "주문확정"
        default: return status
        }
    }
    
    private func showCancelButton() -> Bool {
        return item.paymentStatus == "50" // 배송준비중
    }
    
    private func showReturnButton() -> Bool {
        guard item.paymentStatus == "70", let deliveredAt = item.deliveredAt else { return false }
        
        // 7-day check
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let cleanDate = deliveredAt.replacingOccurrences(of: "T", with: " ")
        if let delDate = formatter.date(from: cleanDate) {
            let diff = Date().timeIntervalSince(delDate)
            let diffDays = diff / (24 * 3600)
            return diffDays <= 7
        }
        return false
    }
    
    private func formattedPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: Int(price))) ?? "0"
    }
}
