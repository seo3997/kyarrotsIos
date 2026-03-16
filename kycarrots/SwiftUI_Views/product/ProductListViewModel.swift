import Foundation
import Combine

@MainActor
class ProductListViewModel: ObservableObject {
    @Published var items: [AdItem] = []
    @Published var isLoading = false
    @Published var isLastPage = false
    @Published var selectedStatus: SaleStatus = .onSale
    @Published var unreadNotificationCount: Int = 0
    
    private var pageNo = 1
    private let appService = AppServiceProvider.shared
    
    func fetchProducts(isRefresh: Bool = false) {
        guard !isLoading else { return }
        if !isRefresh && isLastPage { return }
        
        isLoading = true
        
        if isRefresh {
            pageNo = 1
            isLastPage = false
            items.removeAll()
        }
        
        let token = TokenUtil.getToken()
        let memberCode = LoginInfoUtil.getMemberCode()
        
        guard !token.isEmpty else {
            isLoading = false
            return
        }
        
        let req = AdListRequest(
            token: token,
            adCode: 1,
            pageno: pageNo,
            saleStatus: selectedStatus.apiCode,
            memberCode: memberCode
        )
        
        Task {
            do {
                let ads = try await appService.getAdvertiseList(req: req)
                if ads.isEmpty {
                    isLastPage = true
                } else {
                    items.append(contentsOf: ads)
                    pageNo += 1
                }
            } catch {
                print("getAdvertiseList error: \(error)")
            }
            isLoading = false
        }
    }
    
    func fetchUnreadCount() {
        let userId = LoginInfoUtil.getUserId()
        Task {
            let count = await NotificationBadgeHelper.fetchUnreadCount(userId: userId)
            self.unreadNotificationCount = count
        }
    }
}
