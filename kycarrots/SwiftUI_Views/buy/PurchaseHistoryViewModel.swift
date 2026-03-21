import Foundation
import Combine

class PurchaseHistoryViewModel: ObservableObject {
    @Published var items: [AdItem] = []
    @Published var isLoading = false
    @Published var isLastPage = false
    
    private var pageNo = 1
    private let appService = AppServiceProvider.shared
    
    func fetchPurchaseList(isRefresh: Bool = false) {
        if isRefresh {
            pageNo = 1
            isLastPage = false
        }
        
        guard !isLoading && !isLastPage else { return }
        
        if isRefresh {
            items.removeAll()
        }
        
        isLoading = true
        let token = TokenUtil.getToken()
        
        Task {
            let ads = await appService.getPurchaseItems(token: token, pageNo: pageNo)
            await MainActor.run {
                if ads.isEmpty {
                    self.isLastPage = true
                } else {
                    if isRefresh {
                        self.items = ads
                    } else {
                        self.items.append(contentsOf: ads)
                    }
                    self.pageNo += 1
                }
                self.isLoading = false
            }
        }
    }
}
