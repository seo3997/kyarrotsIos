import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var items: [AdItem] = []
    @Published var isLoading = false
    @Published var isEndReached = false
    
    // ✅ 사용자 요청 필터 속성 유지
    @Published var isSaleOnly = true
    @Published var isPriceFilterOn = false
    @Published var minPrice: Double = 0
    @Published var maxPrice: Double = 999000
    
    private var currentPage = 1
    private let appService = AppServiceProvider.shared
    
    func loadInitialData() {
        currentPage = 1
        isEndReached = false
        items.removeAll()
        fetchProducts()
    }
    
    func fetchProducts() {
        guard !isLoading && !isEndReached else { return }
        
        isLoading = true
        
        // Android HomeFragment.kt 기준: 사용자 요청 조건 반영
        let request = AdListRequest(
            token: TokenUtil.getToken(),
            adCode: 1,
            pageno: currentPage,
            minPrice: isPriceFilterOn ? Int(minPrice) : 0,
            maxPrice: isPriceFilterOn ? Int(maxPrice) : 999000,
            saleStatus: isSaleOnly ? "1" : "0"
        )
        
        Task {
            let response = await appService.getBuyAdvertiseList(req: request)
            await MainActor.run {
                if !response.isEmpty {
                    self.items.append(contentsOf: response)
                    self.currentPage += 1
                } else {
                    self.isEndReached = true
                }
                self.isLoading = false
            }
        }
    }
}
