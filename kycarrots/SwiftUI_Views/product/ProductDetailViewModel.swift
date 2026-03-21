import Foundation
import Combine
import SwiftUI

class ProductDetailViewModel: ObservableObject {
    @Published var productDetail: ProductDetailResponse?
    @Published var isLoading = false
    @Published var isFavorite = false
    @Published var statusOptions: [TxtListDataInfo] = []
    @Published var selectedStatus: TxtListDataInfo?
    @Published var unreadNotificationCount = 0
    @Published var baseShippingFee: Int = 0
    @Published var freeShippingThreshold: Int = 0
    @Published var isBuyer: Bool = false
    @Published var currentUserId: String = ""
    @Published var errorMessage: String?
    
    // Dependencies lds for Tabs
    @Published var selectedTab: Int = 0
    @Published var reviews: [ReviewVo] = []
    @Published var qnas: [QnaVo] = []
    @Published var quantity: Int = 1 {
        didSet {
            if quantity < 1 { quantity = 1 }
        }
    }
    
    var totalPrice: Int {
        guard let priceStr = productDetail?.product.price else { return 0 }
        let cleanPrice = priceStr.replacingOccurrences(of: ",", with: "")
        let price = Int(Double(cleanPrice) ?? 0)
        return price * quantity
    }
    
    let productId: Int64
    private var cancellables = Set<AnyCancellable>()
    
    // Member Info
    private let memberCode = LoginInfoUtil.getMemberCode()
    
    init(productId: Int64) {
        self.productId = productId
        self.baseShippingFee = LoginInfoUtil.getBaseShippingFee()
        self.freeShippingThreshold = LoginInfoUtil.getFreeShippingThreshold()
        self.isBuyer = (LoginInfoUtil.getMemberCode() == Constants.ROLE_PUB)
        self.currentUserId = LoginInfoUtil.getUserNo()
    }
    
    func fetchData() {
        print("🔍 [ViewModel] fetchData called for productId: \(productId)")
        guard productId > 0 else { 
            print("⚠️ [ViewModel] Invalid productId: \(productId)")
            return 
        }
        
        isLoading = true
        
        Task {
            print("🌐 [ViewModel] Starting task to fetch product detail...")
            do {
                let userNo = Int64(LoginInfoUtil.getUserNo()) ?? 0
                print("👨‍💼 [ViewModel] userNo: \(userNo), productId: \(productId)")
                
                let detail = try await AppServiceProvider.shared.getProductDetail(productId: productId, userNo: userNo)
                
                print("📦 [ViewModel] Network result received. detail is nil? \(detail == nil)")
                
                await MainActor.run {
                    if let detail = detail {
                        print("✅ [ViewModel] Successfully decoded detail for product: \(detail.product.title)")
                        self.productDetail = detail
                        self.isFavorite = (detail.product.fav == "Y" || detail.product.fav == "1")
                        self.quantity = 1
                        self.loadStatusOptions(currentStatus: detail.product.saleStatus)
                        
                        // Initial Tab Data based on current selection
                        if self.selectedTab == 1 { self.loadReviews() }
                        else if self.selectedTab == 2 { self.loadQnas() }
                    } else {
                        print("❌ [ViewModel] detail was nil - likely a decoding error in AppService/Repo")
                        self.errorMessage = "상품 정보를 가져오지 못했습니다. (데이터 매핑 확인 필요)"
                    }
                    self.isLoading = false
                    print("🏁 [ViewModel] isLoading set to false")
                }
            } catch {
                print("🔥 [ViewModel] Error in fetchData: \(error)")
                await MainActor.run {
                    self.errorMessage = "네트워크 오류: \(error.localizedDescription)"
                    self.isLoading = false
                    print("🏁 [ViewModel] isLoading set to false after error")
                }
            }
        }
    }
    
    func loadStatusOptions(currentStatus: String?) {
        guard memberCode != Constants.ROLE_PUB else {
            self.statusOptions = []
            return
        }
        
        // Hide if readonly conditions met
        if memberCode == Constants.ROLE_SELL && currentStatus == "0" { return }
        if memberCode == Constants.ROLE_PROJ && currentStatus == "98" { return }

        Task {
            do {
                let list = try await AppServiceProvider.shared.getCodeList(groupId: "R010630")
                await MainActor.run {
                    self.statusOptions = list.filter { item in
                        let idx = item.strIdx
                        switch memberCode {
                        case Constants.ROLE_PROJ:
                            return ["0","1","10","98","99"].contains(idx) || idx == currentStatus
                        case Constants.ROLE_SELL:
                            return ["0","98"].contains(idx) || idx == currentStatus
                        default:
                            return false
                        }
                    }
                    
                    // Distinct by strIdx
                    let dict = Dictionary(grouping: self.statusOptions, by: { $0.strIdx ?? "" })
                    self.statusOptions = dict.values.compactMap { $0.first }
                    
                    self.selectedStatus = self.statusOptions.first(where: { $0.strIdx == currentStatus })
                }
            } catch {
                print("Error loading status options: \(error)")
            }
        }
    }
    
    func toggleFavorite() {
        guard memberCode == Constants.ROLE_PUB else { return }
        
        Task {
            do {
                let userNo = Int64(LoginInfoUtil.getUserNo()) ?? 0
                let req = InterestRequest(userNo: userNo, productId: productId)
                let success = try await AppServiceProvider.shared.toggleInterest(req)
                
                await MainActor.run {
                    if success {
                        self.isFavorite.toggle()
                    }
                }
            } catch {
                print("Error toggling favorite: \(error)")
            }
        }
    }
    
    func updateStatus(code: String, rejectReason: String? = nil, buyer: ChatBuyerDto? = nil) async -> Bool {
        do {
            await MainActor.run { self.isLoading = true }
            
            // Create purchase history if completing sale
            if code == "99", let buyer = buyer {
                let req = PurchaseHistoryRequest(
                    productId: productId,
                    buyerNo: buyer.buyerNo,
                    roomId: buyer.roomId,
                    sellerNo: buyer.sellerNo
                )
                _ = try await AppServiceProvider.shared.createPurchase(req)
            }
            
            let token = TokenUtil.getToken()
            let item = ProductItem(
                productId: String(productId),
                saleStatus: code,
                updusrNo: 0,
                rejectReason: rejectReason,
                systemType: "2"
            )
            
            let success = try await AppServiceProvider.shared.updateProductStatus(token: token, product: item)
            
            await MainActor.run {
                if success {
                    self.fetchData() // Refresh
                }
                self.isLoading = false
            }
            return success
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
    
    func getChatBuyers(branchId: String? = nil) async -> [ChatBuyerDto] {
        do {
            let targetBranchId = branchId ?? LoginInfoUtil.getBranchId()
            return try await AppServiceProvider.shared.getChatBuyers(productId: productId, branchId: targetBranchId)
        } catch {
            return []
        }
    }
    
    func createOrGetChatRoom(buyerId: String, branchId: String) async -> ChatRoomResponse? {
        let pid = String(productId)
        do {
            return try await AppServiceProvider.shared.createOrGetChatRoom(productId: pid, buyerId: buyerId, branchId: branchId)
        } catch {
            return nil
        }
    }
    
    func getUserChatRooms(branchId: String? = nil) async -> [ChatRoomResponse] {
        let targetBranchId = branchId ?? LoginInfoUtil.getBranchId()
        let pid = String(productId)
        do {
            return try await AppServiceProvider.shared.getUserChatRooms(productId: pid, userId: targetBranchId)
        } catch {
            return []
        }
    }
    
    // MARK: - Tab Data Loading
    func loadReviews() {
        print("🔍 [ViewModel] loadReviews called for productId: \(productId)")
        Task {
            let list = await AppServiceProvider.shared.getReviewList(productId: productId)
            await MainActor.run { self.reviews = list }
        }
    }
    
    func loadQnas() {
        print("🔍 [ViewModel] loadQnas called for productId: \(productId)")
        Task {
            let list = await AppServiceProvider.shared.getQnaList(productId: productId)
            await MainActor.run { self.qnas = list }
        }
    }
    
    func editQna(_ qna: QnaVo) {
        // Implementation for QnA edit (e.g., show sheet/navigation)
        print("Edit QnA: \(qna.qnaId ?? "")")
    }
    
    func deleteQna(_ qna: QnaVo) {
        Task {
            let token = TokenUtil.getToken()
            let success = await AppServiceProvider.shared.deleteQna(qnaId: qna.qnaId ?? "", token: token)
            if success == true {
                await MainActor.run { self.loadQnas() }
            }
        }
    }
    
    func editReview(_ review: ReviewVo) {
        // Implementation for Review edit
        print("Edit Review: \(review.reviewId ?? "")")
    }
    
    func deleteReview(_ review: ReviewVo) {
        Task {
            let token = TokenUtil.getToken()
            let success = await AppServiceProvider.shared.deleteReview(reviewId: review.reviewId ?? "", token: token)
            if success == true {
                await MainActor.run { self.loadReviews() }
            }
        }
    }
    
    func showImage(_ path: String) {
        // Trigger image viewer
        print("Show Image: \(path)")
    }
    
    func updateProductStatus(selectedCode: String) {
        Task {
            _ = await updateStatus(code: selectedCode)
        }
    }
}
