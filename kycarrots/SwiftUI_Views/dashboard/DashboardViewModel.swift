import Foundation
import SwiftUI
import Combine

class DashboardViewModel: ObservableObject {
    @Published var dashboardData: [String: Any] = [:]
    @Published var stats: [DashboardStatItem] = []
    @Published var recentOrders: [DashboardOrder] = []
    @Published var isLoading: Bool = false
    @Published var hqNotice: String = ""
    @Published var dashboardTitle: String = "대시보드"
    @Published var unreadNotificationCount: Int = 0
    
    private let appService = AppServiceProvider.shared
    
    init() {
        loadData()
    }
    
    @MainActor
    func loadData() {
        let token = TokenUtil.getToken()
        guard !token.isEmpty else { return }
        
        self.isLoading = true
        
        Task {
            do {
                if let result = try await appService.getDashboardMgtData(token: token) {
                    processDashboardData(result)
                }
                
                // Fetch unread count
                let userId = LoginInfoUtil.getUserId()
                self.unreadNotificationCount = await NotificationBadgeHelper.fetchUnreadCount(userId: userId)
            } catch {
                print("Dashboard Load Error:", error)
            }
            self.isLoading = false
        }
    }
    
    private func processDashboardData(_ data: [String: Any]) {
        self.dashboardData = data
        let role = LoginInfoUtil.getMemberCode()
        let branchName = LoginInfoUtil.getBranchName()
        
        // 1. Title matching Android DashboardActivity.kt
        switch role {
        case "ROLE_ADMIN": self.dashboardTitle = "시스템 관리자 모드"
        case "ROLE_SELL":  self.dashboardTitle = "본사 통합 관리 시스템"
        case "ROLE_PROJ":  self.dashboardTitle = "지점 판매 어드민 [\(branchName)]"
        default:           self.dashboardTitle = "대시보드"
        }
        
        // 2. Stats matching Android logic
        let statsMap = data["dashboardStats"] as? [String: Any] ?? [:]
        var items: [DashboardStatItem] = []
        
        switch role {
        case "ROLE_ADMIN":
            items = [
                .init(label: "총 사용자 수", value: formatNumber(statsMap["totalUsers"]), color: .blue, icon: "person.2.fill"),
                .init(label: "지점 수", value: formatNumber(statsMap["totalBranches"]), color: .indigo, icon: "building.2.fill"),
                .init(label: "누적 주문", value: formatNumber(statsMap["totalOrders"]), color: .red, icon: "cart.fill"),
                .init(label: "누적 매출", value: formatCurrency(statsMap["totalRevenue"]), color: .green, icon: "wonsign.circle.fill")
            ]
            
        case "ROLE_SELL":
            items = [
                .init(label: "미처리 주문", value: formatNumber(statsMap["unprocessedOrders"]), color: .blue, icon: "clock.fill"),
                .init(label: "지점 미입금액", value: formatCurrency(statsMap["branchPendingAmount"]), color: .red, icon: "exclamationmark.triangle.fill"),
                .init(label: "출고 대기", value: formatNumber(statsMap["shipmentPending"]), color: .green, icon: "shippingbox.fill"),
                .init(label: "배송 중", value: formatNumber(statsMap["inTransit"]), color: .cyan, icon: "truck.box.fill")
            ]
            
        case "ROLE_PROJ":
            items = [
                .init(label: "오늘의 매출", value: formatCurrency(statsMap["todayTotalSales"]), color: .blue, icon: "chart.line.uptrend.xyaxis"),
                .init(label: "예상 순이익", value: formatCurrency(statsMap["estimatedProfit"]), color: .indigo, icon: "banknote.fill"),
                .init(label: "본사 송금 대기", value: formatNumber(statsMap["remittancePending"]), color: .red, icon: "arrow.right.arrow.left.circle.fill"),
                .init(label: "이달의 주문", value: formatNumber(statsMap["completedOrders"]), color: .green, icon: "calendar")
            ]
            
            // HQ Notice
            if let hq = data["headQuarterBranch"] as? [String: Any] {
                let bank = hq["BANK_NM"] as? String ?? ""
                let acc = hq["ACCOUNT_NO"] as? String ?? ""
                let holder = hq["ACCOUNT_HOLDER"] as? String ?? ""
                if !bank.isEmpty {
                    self.hqNotice = "본사 입금 안내: \(bank) \(acc) (예금주: \(holder))로 입금하셔야 배송이 시작됩니다."
                }
            }
            
        default:
            break
        }
        self.stats = items
        
        // 3. Recent Orders
        if let ordersList = data["dashboardOrderList"] as? [[String: Any]] {
            self.recentOrders = ordersList.map { DashboardOrder(dict: $0) }
        } else {
            self.recentOrders = []
        }
    }
    
    private func formatCurrency(_ value: Any?) -> String {
        let val = (value as? NSNumber)?.intValue ?? Int(value as? String ?? "0") ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: val)) ?? "₩0"
    }
    
    private func formatNumber(_ value: Any?) -> String {
        let val = (value as? NSNumber)?.intValue ?? Int(value as? String ?? "0") ?? 0
        return "\(val)건"
    }
}

struct DashboardStatItem: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let color: SwiftUI.Color
    let icon: String
}

struct DashboardOrder: Identifiable {
    let id = UUID()
    let orderId: String
    let orderNo: String
    let branchName: String
    let date: String
    let amount: String
    let status: String
    
    init(dict: [String: Any]) {
        self.orderId = (dict["ORDER_ID"] ?? dict["orderId"] ?? "").asString()
        self.orderNo = (dict["ORDER_NO"] ?? dict["orderNo"] ?? "").asString()
        self.branchName = (dict["BRANCH_NAME"] ?? dict["branchName"] ?? "").asString()
        self.date = (dict["ORDERED_AT"] ?? dict["orderedAt"] ?? dict["ORDER_DATE"] ?? "").asString()
        
        let rawAmt = dict["TOTAL_PAY_AMOUNT"] ?? dict["totalPayAmount"] ?? dict["SUPPLY_PRICE_SUM"] ?? dict["supplyPriceSum"] ?? 0
        let amtValue: Double
        if let dbl = rawAmt as? Double {
            amtValue = dbl
        } else if let str = rawAmt as? String {
            amtValue = Double(str) ?? 0
        } else if let num = rawAmt as? NSNumber {
            amtValue = num.doubleValue
        } else {
            amtValue = 0
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        self.amount = formatter.string(from: NSNumber(value: Int(amtValue))) ?? "₩0"
        
        self.status = (dict["ORDER_STATUS_NM"] ?? dict["orderStatusNm"] ?? dict["ORDER_STATUS"] ?? "").asString()
    }
}
