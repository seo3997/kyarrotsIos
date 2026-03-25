import SwiftUI

struct DashboardSwiftUIView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var onShowNotifications: (() -> Void)?
    var onToggleMenu: (() -> Void)?
    var onSelectOrder: ((DashboardOrder) -> Void)?
    var onShowOrderMgt: (() -> Void)?
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Navigation Bar)
                HStack {
                    Button(action: {
                        onToggleMenu?()
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Text(viewModel.dashboardTitle)
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    NotificationBellButton {
                        onShowNotifications?()
                    }
                }
                .padding()
                .background(Color.white)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // HQ Notice (Only for Branch)
                        if !viewModel.hqNotice.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text(viewModel.hqNotice)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Stats Grid (2x2)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(viewModel.stats) { stat in
                                DashboardStatCard(stat: stat)
                            }
                        }
                        
                        // Recent Orders Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("최근 주문 현황")
                                    .font(.system(size: 17, weight: .bold))
                                Spacer()
                                Button(action: {
                                    onShowOrderMgt?()
                                }) {
                                    Text("전체보기 >")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            VStack(spacing: 0) {
                                if viewModel.recentOrders.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "cart")
                                            .font(.system(size: 32))
                                            .foregroundColor(.gray.opacity(0.5))
                                        Text("최근 주문 내역이 없습니다.")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    ForEach(viewModel.recentOrders) { order in
                                        Button(action: {
                                            onSelectOrder?(order)
                                        }) {
                                            OrderDashboardRow(order: order)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        if order.id != viewModel.recentOrders.last?.id {
                                            Divider().padding(.horizontal, 16)
                                        }
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(16)
                }
                .refreshable {
                    viewModel.loadData()
                }
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.1).ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .navigationBarHidden(true)
    }
}

// ---------------------------------------------------------
// Simplified Stat Card
struct DashboardStatCard: View {
    let stat: DashboardStatItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: stat.icon)
                    .font(.system(size: 16))
                    .foregroundColor(stat.color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stat.label)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text(stat.value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(stat.color)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// ---------------------------------------------------------
// Order Row for Dashboard
struct OrderDashboardRow: View {
    let order: DashboardOrder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(order.branchName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(order.status)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("주문번호: \(order.orderNo)")
                        .font(.system(size: 14, weight: .medium))
                    Text(order.date)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(order.amount)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
    }
}

struct DashboardSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardSwiftUIView()
    }
}
