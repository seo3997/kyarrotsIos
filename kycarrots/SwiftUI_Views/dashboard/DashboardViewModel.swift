import Foundation
import Combine
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    // Original Stats (Products)
    @Published var totalProducts: Int = 0
    @Published var rejectedCount: Int = 0
    @Published var processingCount: Int = 0
    @Published var completedCount: Int = 0
    @Published var recentProducts: [RecentProductViewModel] = []
    
    // New Stats (Orders & Financials)
    @Published var stats: [String: Any] = [:]
    @Published var recentOrders: [[String: Any]] = []
    @Published var hqNotice: String?
    
    @Published var isLoading = false
    @Published var unreadNotificationCount: Int = 0
    @Published var errorMessage: String?
    
    @Published var isWholesalerShowing = false
    @Published var wholesalers: [OpUserVO] = []
    
    private let appService = AppServiceProvider.shared
    
    func fetchDashboardData() {
        let token = TokenUtil.getToken()
        guard !token.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                // 1. Fetch Original Product Stats
                let pStats = try await appService.getProductDashboard(token: token)
                self.totalProducts = pStats["totalCount"] ?? 0
                self.rejectedCount = pStats["reguestCount"] ?? 0
                self.processingCount = pStats["processingCount"] ?? 0
                self.completedCount = pStats["completedCount"] ?? 0
                
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
                
                // 3. Fetch New Order Management Stats (Roles-based)
                if let mgtData = await appService.getDashboardMgtData(token: token) {
                    self.stats = mgtData["dashboardStats"] as? [String: Any] ?? [:]
                    self.recentOrders = mgtData["dashboardOrderList"] as? [[String: Any]] ?? []
                    
                    if let hq = mgtData["headQuarterBranch"] as? [String: Any] {
                        let bank = hq["BANK_NM"] as? String ?? ""
                        let acc = hq["ACCOUNT_NO"] as? String ?? ""
                        let holder = hq["ACCOUNT_HOLDER"] as? String ?? ""
                        self.hqNotice = "본사 입금 안내: \(bank) \(acc) (예금주: \(holder))"
                    }
                }
                
                fetchUnreadCount()
                
            } catch {
                print("Dashboard fetch error: \(error)")
                self.errorMessage = "대시보드 데이터를 불러오는 중 오류가 발생했습니다."
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
                if defaultWholesalerNo > 0 {
                    isLoading = false
                    onReady()
                    return
                }
                
                let wholesalerList = try await appService.getWholesalers(memberCode: "ROLE_PROJ")
                isLoading = false
                if wholesalerList.isEmpty {
                    // Handled by view
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
                let ok = await appService.setDefaultWholesaler(userId: userId, wholesalerNo: userNo)
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
