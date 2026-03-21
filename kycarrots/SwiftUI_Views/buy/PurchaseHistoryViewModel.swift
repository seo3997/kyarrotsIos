import Foundation
import Combine

class PurchaseHistoryViewModel: ObservableObject {
    @Published var items: [AdItem] = []
    @Published var isLoading = false
    @Published var isLastPage = false
    @Published var errorMessage: String? = nil
    
    private var pageNo = 0
    private let appService = AppServiceProvider.shared
    
    func fetchPurchaseList(isRefresh: Bool = false) {
        if isRefresh {
            pageNo = 0
            isLastPage = false
            items.removeAll()
        }
        
        guard !isLoading && !isLastPage else { return }
        
        isLoading = true
        let userNo = Int64(LoginInfoUtil.getUserNo()) ?? 0
        
        Task {
            let ads = await appService.getOrderHistory(buyerNo: userNo, page: pageNo)
            await MainActor.run {
                if ads.isEmpty {
                    self.isLastPage = true
                } else {
                    self.items.append(contentsOf: ads)
                    self.pageNo += 1
                }
                self.isLoading = false
            }
        }
    }

    func cancelOrder(item: AdItem) {
        guard let orderId = item.orderId else { return }
        
        // 7-day check
        if let orderedAt = item.orderedAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            // Some formats might use "." as separator
            let cleanDate = orderedAt.replacingOccurrences(of: ".", with: "-")
            if let orderDate = formatter.date(from: cleanDate) {
                let diff = Date().timeIntervalSince(orderDate)
                let diffDays = diff / (24 * 3600)
                if diffDays > 7 {
                    self.errorMessage = "결제 후 7일이 경과하여 직접 취소가 불가능합니다."
                    return
                }
            }
        }

        isLoading = true
        let userNo = Int64(LoginInfoUtil.getUserNo()) ?? 0
        let req = OrderCancelRequest(orderId: orderId, cancelReason: "고객 변심", userNo: userNo)
        
        Task {
            let success = await appService.cancelPayment(req: req)
            await MainActor.run {
                self.isLoading = false
                if success {
                    self.fetchPurchaseList(isRefresh: true)
                } else {
                    self.errorMessage = "취소 처리에 실패했습니다."
                }
            }
        }
    }

    func requestReturn(item: AdItem) {
        guard let orderId = item.orderId else { return }
        
        // 7-day check
        if let deliveredAt = item.deliveredAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let cleanDate = deliveredAt.replacingOccurrences(of: "T", with: " ")
            if let delDate = formatter.date(from: cleanDate) {
                let diff = Date().timeIntervalSince(delDate)
                let diffDays = diff / (24 * 3600)
                if diffDays > 7 {
                    self.errorMessage = "배송 완료 후 7일이 경과하여 반품 요청이 불가능합니다."
                    return
                }
            }
        }

        isLoading = true
        let userNo = Int64(LoginInfoUtil.getUserNo()) ?? 0
        let req = OrderReturnRequest(
            orderId: orderId,
            returnReason: "단순 변심",
            userNo: userNo
        )
        
        Task {
            let success = await appService.requestReturn(req: req)
            await MainActor.run {
                self.isLoading = false
                if success {
                    self.fetchPurchaseList(isRefresh: true)
                } else {
                    self.errorMessage = "반품 요청에 실패했습니다."
                }
            }
        }
    }
}
