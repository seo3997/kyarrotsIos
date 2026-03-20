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
    @Published var errorMessage: String?
    
    let productId: Int64
    private var cancellables = Set<AnyCancellable>()
    
    // Member Info
    private let memberCode = LoginInfoUtil.getMemberCode()
    
    init(productId: Int64) {
        self.productId = productId
    }
    
    func fetchData() {
        guard productId > 0 else { return }
        isLoading = true
        
        Task {
            do {
                let userNo = Int64(LoginInfoUtil.getUserNo()) ?? 0
                if let detail = try await AppServiceProvider.shared.getProductDetail(productId: productId, userNo: userNo) {
                    await MainActor.run {
                        self.productDetail = detail
                        self.isFavorite = (detail.product.fav == "1")
                        self.loadStatusOptions(currentStatus: detail.product.saleStatus)
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
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
    
}
