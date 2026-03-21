import SwiftUI
import Kingfisher

struct DashboardSwiftUIView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    // Callback closures (Keep original ones for navigation)
    var onShowNotifications: (() -> Void)?
    var onAddProduct: (() -> Void)?
    var onSelectProduct: ((RecentProductViewModel) -> Void)?
    var onShowMore: (() -> Void)?
    var onShowApproval: (() -> Void)?
    var onSelectOrder: ((String) -> Void)? // Added for order detail
    
    @State private var showingWholesalerPicker = false
    
    var body: some View {
        ZStack {
            Color(hex: "F1F5F9").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Dynamic Stats Grid based on Role (Premium Theme)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(dashboardTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(statItems, id: \.label) { item in
                                DashboardStatCard(item: item)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // 2. HQ Notice (Visible for BRANCH admins)
                    if let notice = viewModel.hqNotice {
                        Label(notice, systemImage: "info.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // 3. Command Action Buttons (Add Product & Approval)
                    HStack(spacing: 12) {
                        if canRegisterProduct {
                            Button(action: {
                                viewModel.checkWholesalerAndMove {
                                    onAddProduct?()
                                } onShowPicker: { _ in
                                    showingWholesalerPicker = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("매물 등록")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        
                        Button(action: { onShowApproval?() }) {
                            HStack {
                                Image(systemName: "checklist")
                                Text("승인 관리")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .foregroundColor(.orange)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange, lineWidth: 1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 4. Recent Order Monitoring (HQ/ 지점용)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("최근 주문 현황")
                                .font(.headline)
                            Spacer()
                            NavigationLink(destination: OrderManagementView()) {
                                Text("주문관리 이동")
                                    .font(.system(size: 13))
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        if viewModel.recentOrders.isEmpty {
                            EmptyListView(message: "최근 주문이 없습니다.")
                        } else {
                            VStack(spacing: 0) {
                                ForEach(0..<viewModel.recentOrders.count, id: \.self) { index in
                                    let order = viewModel.recentOrders[index]
                                    Button(action: {
                                        onSelectOrder?("\(order["ORDER_ID"] ?? order["orderId"] ?? "")")
                                    }) {
                                        DashboardOrderRow(order: order)
                                    }
                                    if index < viewModel.recentOrders.count - 1 { Divider().padding(.vertical, 8) }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 5. Recent Product Status
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("최근 등록 매물")
                                .font(.headline)
                            Spacer()
                            Button(action: { onShowMore?() }) {
                                Text("전체보기")
                                    .font(.system(size: 13))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if viewModel.recentProducts.isEmpty && !viewModel.isLoading {
                            EmptyListView(message: "최근 매물이 없습니다.")
                        } else {
                            VStack(spacing: 0) {
                                ForEach(0..<viewModel.recentProducts.count, id: \.self) { index in
                                    let item = viewModel.recentProducts[index]
                                    RecentProductRowView(item: item) {
                                        self.onSelectProduct?(item)
                                    }
                                    if index < viewModel.recentProducts.count - 1 {
                                        Divider().padding(.vertical, 8)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .refreshable { viewModel.fetchDashboardData() }
            
            if viewModel.isLoading {
                Color.black.opacity(0.1).ignoresSafeArea()
                ProgressView()
            }
        }
        .navigationTitle("대시보드")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { onShowNotifications?() }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 18))
                            .foregroundColor(.black)
                        
                        if viewModel.unreadNotificationCount > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
            }
        }
        .actionSheet(isPresented: $showingWholesalerPicker) {
            ActionSheet(
                title: Text("도매상 선택"),
                buttons: viewModel.wholesalers.map { w in
                    .default(Text("\(w.userNm ?? "")(\(w.userNo ?? "0"))")) {
                        viewModel.setSelectedWholesaler(w.userNo ?? "") { onAddProduct?() }
                    }
                } + [.cancel(Text("취소"))]
            )
        }
        .onAppear {
            viewModel.fetchDashboardData()
        }
    }
    
    // MARK: - Sub Views
    private var dashboardTitle: String {
        let code = LoginInfoUtil.getMemberCode()
        switch code {
        case Constants.ROLE_ADMIN: return "전체 시스템 현황"
        case Constants.ROLE_SELL: return "본사 통합 사령부"
        case Constants.ROLE_PROJ: return "[\(LoginInfoUtil.getBranchName())] 지점 현황"
        default: return "관리자 대시보드"
        }
    }
    
    private var statItems: [DashboardStatItem] {
        let code = LoginInfoUtil.getMemberCode()
        let stats = viewModel.stats
        
        switch code {
        case Constants.ROLE_ADMIN:
            return [
                DashboardStatItem(label: "전체 회원", value: "\(stats["totalUsers"] ?? 0)", color: .blue, icon: "person.2.fill"),
                DashboardStatItem(label: "입점 지점", value: "\(stats["totalBranches"] ?? 0)", color: .indigo, icon: "building.2.fill"),
                DashboardStatItem(label: "전체 주문", value: "\(stats["totalOrders"] ?? 0)", color: .red, icon: "cart.fill"),
                DashboardStatItem(label: "누적 거래액", value: formatCurrency(stats["totalRevenue"] ?? 0), color: .green, icon: "wonsign.circle.fill")
            ]
        case Constants.ROLE_SELL:
            return [
                DashboardStatItem(label: "미승인 주문", value: "\(stats["unprocessedOrders"] ?? 0)", color: .orange, icon: "clock.badge.exclamationmark.fill"),
                DashboardStatItem(label: "지점 미송금", value: formatCurrency(stats["branchPendingAmount"] ?? 0), color: .red, icon: "exclamationmark.arrow.triangle.2.circlepath"),
                DashboardStatItem(label: "출고 대기", value: "\(stats["shipmentPending"] ?? 0)", color: .teal, icon: "box.truck.fill"),
                DashboardStatItem(label: "배송 중", value: "\(stats["inTransit"] ?? 0)", color: .blue, icon: "shippingbox.fill")
            ]
        case Constants.ROLE_PROJ:
            return [
                DashboardStatItem(label: "오늘의 매출", value: formatCurrency(stats["todayTotalSales"] ?? 0), color: .blue, icon: "chart.line.uptrend.xyaxis"),
                DashboardStatItem(label: "본사 미입금", value: "\(stats["remittancePending"] ?? 0)건", color: .red, icon: "arrow.right.arrow.left.circle.fill"),
                DashboardStatItem(label: "배송 대기", value: "\(stats["shipmentPending"] ?? 0)", color: .orange, icon: "shippingbox.fill"),
                DashboardStatItem(label: "정산 예정", value: formatCurrency(stats["estimatedProfit"] ?? 0), color: .green, icon: "banknote.fill")
            ]
        default: return []
        }
    }
    
    private var canRegisterProduct: Bool {
        let code = LoginInfoUtil.getMemberCode()
        return code == Constants.ROLE_SELL || code == Constants.ROLE_PROJ
    }
    
    private func formatCurrency(_ value: Any) -> String {
        let amt = Int(String(describing: value)) ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: amt)) ?? "0원"
    }
}

// MARK: - Components
struct DashboardStatItem {
    let label: String
    let value: String
    let color: Color
    let icon: String // Added Icon
}

struct DashboardStatCard: View {
    let item: DashboardStatItem
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: item.icon)
                    .font(.system(size: 16))
                    .foregroundColor(item.color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.label)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Text(item.value)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

struct DashboardOrderRow: View {
    let order: [String: Any]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(order["BRANCH_NAME"] as? String ?? order["branchName"] as? String ?? "").font(.system(size: 14, weight: .bold))
                Spacer()
                Text(order["ORDER_STATUS_NM"] as? String ?? order["orderStatusNm"] as? String ?? "").font(.system(size: 12)).padding(.horizontal, 8).padding(.vertical, 2).background(Color.orange.opacity(0.1)).foregroundColor(.orange).cornerRadius(4)
            }
            HStack {
                Text(order["ORDER_DATE"] as? String ?? order["ORDERED_AT"] as? String ?? "").font(.system(size: 12)).foregroundColor(.gray)
                Spacer()
                Text(formatCurrency(order["TOTAL_PAY_AMOUNT"] ?? order["SUPPLY_PRICE_SUM"] ?? 0)).font(.system(size: 14, weight: .bold))
            }
        }
        .padding(.vertical, 4)
        .foregroundColor(.black)
    }
    private func formatCurrency(_ value: Any) -> String {
        let amt = Int(String(describing: value)) ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: amt)) ?? "0원"
    }
}

struct EmptyListView: View {
    let message: String
    var body: some View {
        Text(message).font(.system(size: 14)).foregroundColor(.gray).padding(.vertical, 40).frame(maxWidth: .infinity).background(Color.white).cornerRadius(12)
    }
}

struct RecentProductRowView: View {
    let item: RecentProductViewModel
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let urlString = item.imageUrl, let url = URL(string: urlString) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    Text(item.subInfo)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if let status = item.statusName {
                    Text(status)
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
            }
            .padding(.vertical, 6)
        }
    }
}
