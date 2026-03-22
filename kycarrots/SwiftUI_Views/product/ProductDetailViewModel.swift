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
    
    // UI State for Sheets
    enum ProductDetailSheet: Identifiable {
        case reviewWrite(ReviewVo?) // Edit mode if non-nil
        case qnaWrite(QnaVo?)      // Edit mode if non-nil
        
        var id: String {
            switch self {
            case .reviewWrite(let r): return "review_\(r?.reviewId ?? "new")"
            case .qnaWrite(let q): return "qna_\(q?.qnaId ?? "new")"
            }
        }
    }
    @Published var activeSheet: ProductDetailSheet?
    @Published var chatRooms: [ChatRoomResponse] = []
    @Published var showChatBuyerSelection = false
    @Published var roomsForSelection: [ChatRoomResponse] = []
    @Published var showRoomSelectionSheet = false
    
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
                
                // Prefetch all data in parallel to avoid tab display delays
                async let productTask = AppServiceProvider.shared.getProductDetail(productId: productId, userNo: userNo)
                async let reviewsTask = AppServiceProvider.shared.getReviewList(productId: productId)
                async let qnasTask = AppServiceProvider.shared.getQnaList(productId: productId)
                
                let (detail, reviews, qnas) = await (productTask, reviewsTask, qnasTask)
                
                print("📦 [ViewModel] All data fetched. Detail: \(detail != nil), Reviews: \(reviews.count), Qnas: \(qnas.count)")
                
                await MainActor.run {
                    if let detail = detail {
                        print("✅ [ViewModel] Successfully decoded detail for product: \(detail.product.title)")
                        self.productDetail = detail
                        self.isFavorite = (detail.product.fav == "Y" || detail.product.fav == "1")
                        self.quantity = 1
                        self.loadStatusOptions(currentStatus: detail.product.saleStatus)
                    } else {
                        print("❌ [ViewModel] detail was nil - likely a decoding error in AppService/Repo")
                        self.errorMessage = "상품 정보를 가져오지 못했습니다. (데이터 매핑 확인 필요)"
                    }
                    
                    self.reviews = reviews
                    self.qnas = qnas
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
    
    // MARK: - Tab Data Actions
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
    
    // MARK: - Review & QnA Write/Edit
    func startReviewWrite(review: ReviewVo? = nil) {
        activeSheet = .reviewWrite(review)
    }
    
    func startQnaWrite(qna: QnaVo? = nil) {
        activeSheet = .qnaWrite(qna)
    }

    func submitReview(reviewId: String?, rating: Int, contents: String, images: [Data]?) {
        guard !contents.isEmpty else { return }
        
        isLoading = true
        Task {
            let token = TokenUtil.getToken()
            let branchId = LoginInfoUtil.getBranchId()
            let success: Bool
            
            if let rId = reviewId {
                // Update
                success = await AppServiceProvider.shared.updateReview(reviewId: rId, rating: rating, contents: contents, token: token, branchId: branchId, images: images)
            } else {
                // Insert
                success = await AppServiceProvider.shared.insertReview(productId: String(productId), rating: rating, contents: contents, token: token, branchId: branchId, images: images)
            }
            
            await MainActor.run {
                if success {
                    self.activeSheet = nil
                    self.loadReviews()
                } else {
                    self.errorMessage = "리뷰 저장에 실패했습니다."
                }
                self.isLoading = false
            }
        }
    }

    func submitQna(qnaId: String?, title: String, contents: String, secretYn: String) {
        guard !title.isEmpty && !contents.isEmpty else { return }
        
        isLoading = true
        Task {
            let token = TokenUtil.getToken()
            let branchId = LoginInfoUtil.getBranchId()
            let successResult: Bool
            
            if let qId = qnaId {
                // Update
                successResult = await AppServiceProvider.shared.updateQna(qnaId: qId, title: title, contents: contents, secretYn: secretYn, token: token, branchId: branchId)
            } else {
                // Insert
                successResult = await AppServiceProvider.shared.insertQna(productId: String(productId), title: title, contents: contents, secretYn: secretYn, token: token, branchId: branchId)
            }
            
            await MainActor.run {
                if successResult {
                    self.activeSheet = nil
                    self.loadQnas()
                } else {
                    self.errorMessage = "문의 저장에 실패했습니다."
                }
                self.isLoading = false
            }
        }
    }
    
    func editQna(_ qna: QnaVo) {
        startQnaWrite(qna: qna)
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
        startReviewWrite(review: review)
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
