import SwiftUI
import Combine

class OrderManagementViewModel: ObservableObject {
    @Published var orders: [[String: Any]] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    @Published var selectedStatus: String = ""
    @Published var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var searchKeyword: String = ""
    
    private let service: AppService
    
    let statusOptions = [
        ("전체", ""),
        ("입금대기", "10"),
        ("승인대기", "20"),
        ("배송준비", "30"),
        ("취소", "40"),
        ("입금완료", "50"),
        ("배송중", "60"),
        ("배송완료", "70"),
        ("주문확정", "99")
    ]
    
    init(service: AppService = AppService(repo: RemoteRepository())) {
        self.service = service
    }
    
    func loadOrders() {
        let token = TokenUtil.getToken()
        guard !token.isEmpty else { return }
        isLoading = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let stDt = formatter.string(from: startDate)
        let edDt = formatter.string(from: endDate)
        
        Task {
            if let data = await service.getOrderMgtList(
                token: token,
                status: selectedStatus.isEmpty ? nil : selectedStatus,
                stDate: stDt,
                edDate: edDt,
                keyword: searchKeyword.isEmpty ? nil : searchKeyword
            ) {
                await MainActor.run {
                    self.isLoading = false
                    self.orders = data["list"] as? [[String: Any]] ?? []
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "주문 목록을 불러오지 못했습니다."
                }
            }
        }
    }
}

struct OrderManagementView: View {
    @StateObject var viewModel = OrderManagementViewModel()
    @State private var showFilters = false
    
    var body: some View {
        ZStack {
            Color(hex: "F8F9FA").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("주문번호, 주문자 검색", text: $viewModel.searchKeyword, onCommit: {
                        viewModel.loadOrders()
                    })
                    .font(.system(size: 14))
                    
                    if !viewModel.searchKeyword.isEmpty {
                        Button(action: {
                            viewModel.searchKeyword = ""
                            viewModel.loadOrders()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
                .padding()
                
                // Active Filters Summary
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            OrderFilterChip(label: currentStatusLabel, isActive: !viewModel.selectedStatus.isEmpty) {
                                showFilters = true
                            }
                            
                            OrderFilterChip(label: dateRangeLabel, isActive: true) {
                                showFilters = true
                            }
                        }
                    }
                    Spacer()
                    Button(action: { showFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.orders.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "cart.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.3))
                        Text("검색 결과가 없습니다.")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.orders, id: \.self.description) { order in
                            NavigationLink(destination: OrderMgtDetailView(orderId: "\(order["ORDER_ID"] ?? order["orderId"] ?? "")")) {
                                OrderMgtRow(order: order)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        viewModel.loadOrders()
                    }
                }
            }
        }
        .navigationTitle("주문 관리")
        .onAppear {
            viewModel.loadOrders()
        }
        .sheet(isPresented: $showFilters) {
            OrderFilterSheet(viewModel: viewModel)
        }
    }
    
    private var currentStatusLabel: String {
        viewModel.statusOptions.first(where: { $0.1 == viewModel.selectedStatus })?.0 ?? "상태 전체"
    }
    
    private var dateRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return "\(formatter.string(from: viewModel.startDate)) ~ \(formatter.string(from: viewModel.endDate))"
    }
}

struct OrderFilterChip: View {
    let label: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isActive ? .bold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isActive ? Color.orange.opacity(0.1) : Color.white)
                .foregroundColor(isActive ? .orange : .gray)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isActive ? Color.orange : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .cornerRadius(16)
    }
}

struct OrderMgtRow: View {
    let order: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(order["ORDER_STATUS_NM"] as? String ?? order["orderStatusNm"] as? String ?? "")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.1))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)
                
                Spacer()
                
                Text(order["ORDER_DATE"] as? String ?? order["ORDERED_AT"] as? String ?? "")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Text("주문번호: \(order["ORDER_NO"] as? String ?? "")")
                .font(.system(size: 14, weight: .medium))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order["BRANCH_NAME"] as? String ?? order["branchName"] as? String ?? "")
                        .font(.system(size: 13))
                    Text("주문자: \(order["RECEIVER_NAME"] as? String ?? order["receiverName"] as? String ?? order["USER_NM"] as? String ?? "")")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(formatCurrency(order["TOTAL_PAY_AMOUNT"] ?? order["SUPPLY_PRICE_SUM"] ?? 0))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private var statusColor: Color {
        let status = (order["ORDER_STATUS"] ?? order["orderStatus"]).asString()
        switch status {
        case "10", "20": return .red
        case "30", "50": return .blue
        case "60", "70": return .green
        default: return .gray
        }
    }
    
    private func formatCurrency(_ value: Any) -> String {
        let amt = Int(String(describing: value)) ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: amt)) ?? "0원"
    }
}

struct OrderFilterSheet: View {
    @ObservedObject var viewModel: OrderManagementViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("주문 상태")) {
                    Picker("상태 선택", selection: $viewModel.selectedStatus) {
                        ForEach(viewModel.statusOptions, id: \.1) { opt in
                            Text(opt.0).tag(opt.1)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                
                Section(header: Text("조회 기간")) {
                    DatePicker("시작일", selection: $viewModel.startDate, displayedComponents: .date)
                    DatePicker("종료일", selection: $viewModel.endDate, displayedComponents: .date)
                }
            }
            .navigationTitle("상세 필터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("적용") {
                        viewModel.loadOrders()
                        dismiss()
                    }
                }
            }
        }
    }
}
