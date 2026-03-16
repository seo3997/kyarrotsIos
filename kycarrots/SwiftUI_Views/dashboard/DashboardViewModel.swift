import Foundation
import Combine
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var totalProducts: Int = 0
    @Published var rejectedCount: Int = 0
    @Published var processingCount: Int = 0
    @Published var completedCount: Int = 0
    
    @Published var recentProducts: [RecentProductViewModel] = []
    @Published var isLoading = false
    @Published var unreadNotificationCount: Int = 0
    
    @Published var isWholesalerShowing = false
    @Published var wholesalers: [OpUserVO] = []
    
    private let appService = AppServiceProvider.shared
    
    func fetchDashboardData() {
        let token = TokenUtil.getToken()
        guard !token.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                // 1. Fetch Stats
                let stats = try await appService.getProductDashboard(token: token)
                self.totalProducts = stats["totalCount"] ?? 0
                self.rejectedCount = stats["reguestCount"] ?? 0
                self.processingCount = stats["processingCount"] ?? 0
                self.completedCount = stats["completedCount"] ?? 0
                
                // 2. Fetch Recent Products
                let recentList = try await appService.getRecentProducts(token: token)
                self.recentProducts = recentList.map { product in
                    let qtyInt = Int(product.quantity ?? "") ?? 0
                    let formattedQty = NumberFormatter.localizedString(from: NSNumber(value: qtyInt), number: .decimal)
                    
                    let title = "\(product.title ?? "") \(formattedQty) \(product.unitCodeNm ?? "-")"
                    let subInfo = "\(product.areaMidNm ?? "") \(product.areaSclsNm ?? "") / \(product.desiredShippingDate ?? "")"
                    
                    return RecentProductViewModel(
                        title: title,
                        subInfo: subInfo,
                        statusName: product.saleStatusNm,
                        imageUrl: product.imageUrl,
                        productId: product.productId ?? "",
                        userId: product.userId ?? ""
                    )
                }
            } catch {
                print("Dashboard fetch error: \(error)")
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
    
    func checkWholesalerAndMove(onReady: @escaping () -> Void, onShowPicker: @escaping ([OpUserVO]) -> Void) {
        let userId = LoginInfoUtil.getUserId()
        isLoading = true
        
        Task {
            do {
                let defaultWholesalerNo = try await appService.getDefaultWholesaler(userId: userId)
                if defaultWholesalerNo != nil {
                    isLoading = false
                    onReady()
                    return
                }
                
                let wholesalerList = try await appService.getWholesalers(memberCode: "ROLE_PROJ")
                isLoading = false
                if wholesalerList.isEmpty {
                    // Show error or alert? handled by View
                } else {
                    self.wholesalers = wholesalerList
                    onShowPicker(wholesalerList)
                }
            } catch {
                print("Wholesaler check error: \(error)")
                isLoading = false
            }
        }
    }
    
    func setSelectedWholesaler(_ userNo: String, onComplete: @escaping () -> Void) {
        let userId = LoginInfoUtil.getUserId()
        isLoading = true
        
        Task {
            do {
                let ok = try await appService.setDefaultWholesaler(userId: userId, wholesalerNo: userNo)
                if ok {
                    onComplete()
                }
            } catch {
                print("Set wholesaler error: \(error)")
            }
            isLoading = false
        }
    }
}
