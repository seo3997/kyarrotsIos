import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var items: [AdItem] = []
    @Published var isLoading = false
    @Published var isEndReached = false
    @Published var selectedCategoryMid = "ALL"
    @Published var selectedCategoryScls = "ALL"
    @Published var selectedAreaMid = "ALL"
    @Published var selectedAreaScls = "ALL"
    @Published var isSaleOnly = true
    @Published var isPriceFilterOn = false
    @Published var minPrice: Double = 0
    @Published var maxPrice: Double = 9990000
    
    @Published var categories: [TxtListDataInfo] = []
    @Published var subCategories: [TxtListDataInfo] = []
    @Published var areas: [TxtListDataInfo] = []
    @Published var districts: [TxtListDataInfo] = []
    
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
        
        let request = AdListRequest(
            token: TokenUtil.getToken() ?? "",
            adCode: 1,
            pageno: currentPage,
            categoryGroup: "R010610",
            categoryMid: selectedCategoryMid,
            categoryScls: selectedCategoryScls,
            areaGroup: "R010070",
            areaMid: selectedAreaMid,
            areaScls: selectedAreaScls,
            minPrice: isPriceFilterOn ? Int(minPrice) : 0,
            maxPrice: isPriceFilterOn ? Int(maxPrice) : 9990000,
            saleStatus: isSaleOnly ? "1" : "0",
            memberCode: ""
        )
        
        Task {
            do {
                let response = try await appService.getBuyAdvertiseList(req: request)
                await MainActor.run {
                    if !response.isEmpty {
                        self.items.append(contentsOf: response)
                        self.currentPage += 1
                    } else {
                        self.isEndReached = true
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }
    
    func loadFilterData() {
        Task {
            let cats = await appService.getCodeList(groupId: "R010610")
            let cityList = await appService.getCodeList(groupId: "R010070")
            
            await MainActor.run {
                self.categories = cats
                self.areas = cityList
            }
        }
    }
    
    func loadSubCategories(mcode: String) {
        Task {
            let list = await appService.getSCodeList(groupId: "R010610", mcode: mcode)
            await MainActor.run {
                self.subCategories = list
            }
        }
    }
    
    func loadDistricts(mcode: String) {
        Task {
            let list = await appService.getSCodeList(groupId: "R010070", mcode: mcode)
            await MainActor.run {
                self.districts = list
            }
        }
    }
}
