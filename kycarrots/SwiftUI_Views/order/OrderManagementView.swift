import SwiftUI
import Combine

class OrderManagementViewModel: ObservableObject {
    @Published var orders: [[String: Any]] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    @Published var selectedStatus: String = ""
    @Published var startDate: String? = nil
    @Published var endDate: String? = nil
    @Published var searchKeyword: String = ""
    
    // For date picker display
    @Published var startDateObj: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var endDateObj: Date = Date()
    
    private let service: AppService
    
    // Android OrderMgtActivity.kt Status logic
    @Published var statusOptions: [(String, String)] = [("전체 상태", "")]
    
    init(service: AppService = AppService(repo: RemoteRepository())) {
        self.service = service
    }
    
    @MainActor
    func loadOrders() {
        let token = TokenUtil.getToken()
        guard !token.isEmpty else { return }
        
        self.isLoading = true
        self.errorMessage = nil
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let st = startDate ?? formatter.string(from: startDateObj)
        let ed = endDate ?? formatter.string(from: endDateObj)
        
        Task {
            do {
                if let data = await service.getOrderMgtList(
                    token: token,
                    status: selectedStatus.isEmpty ? nil : selectedStatus,
                    stDate: st,
                    edDate: ed,
                    keyword: searchKeyword.isEmpty ? nil : searchKeyword
                ) {
                    // Android: result["resultList"]
                    self.orders = data["resultList"] as? [[String: Any]] ?? []
                    
                    // Populate status options from server if available
                    if let sList = data["orderStatusList"] as? [[String: Any]] {
                        var opts: [(String, String)] = [("전체 상태", "")]
                        for s in sList {
                            let nm = (s["CODE_NM"] ?? s["codeNm"] ?? "").asString()
                            let cd = (s["CODE"] ?? s["code"] ?? "").asString()
                            if !nm.isEmpty && !cd.isEmpty {
                                opts.append(("\(nm)(\(cd))", cd))
                            }
                        }
                        self.statusOptions = opts
                    }
                    
                    self.isLoading = false
                } else {
                    self.isLoading = false
                    self.errorMessage = "주문 목록을 불러오지 못했습니다."
                }
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

struct OrderManagementView: View {
    @StateObject var viewModel = OrderManagementViewModel()
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    var onToggleMenu: (() -> Void)?
    
    var body: some View {
        ZStack {
            Color(hex: "F8F9FA").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: {
                        print("Hamburger clicked!")
                        onToggleMenu?()
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Text("주문 통합 관리")
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    // Placeholder for balance or notification
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                
                // 1. Search & Filter Header (Emulating Android layout)
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                        TextField("검색어 (주문번호, 지점명)", text: $viewModel.searchKeyword, onCommit: {
                            viewModel.loadOrders()
                        })
                        .font(.system(size: 14))
                        
                        Button(action: {
                            viewModel.loadOrders()
                        }) {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                    .padding(10)
                    .background(Color(hex: "F1F5F9"))
                    .cornerRadius(8)
                    
                    HStack(spacing: 8) {
                        // Status Picker
                        Menu {
                            Picker("상태", selection: $viewModel.selectedStatus) {
                                ForEach(viewModel.statusOptions, id: \.1) { opt in
                                    Text(opt.0).tag(opt.1)
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.statusOptions.first(where: { $0.1 == viewModel.selectedStatus })?.0 ?? "상태 전체")
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "E2E8F0"), lineWidth: 1))
                        }
                        .onChange(of: viewModel.selectedStatus) { _ in
                            viewModel.loadOrders()
                        }
                        
                        // Date Range Button
                        Button(action: {
                            showStartDatePicker = true
                        }) {
                            HStack {
                                Text(dateRangeString)
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "calendar")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "E2E8F0"), lineWidth: 1))
                        }
                    }
                }
                .padding(16)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // 2. Order List
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
                        Text("주문 내역이 없습니다.")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.orders, id: \.self.description) { order in
                                NavigationLink(destination: OrderMgtDetailView(orderId: "\(order["ORDER_ID"] ?? order["orderId"] ?? "")")) {
                                    OrderMgtRow(order: order)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(16)
                    }
                    .refreshable {
                        viewModel.loadOrders()
                    }
                }
            }
        }
        .navigationTitle("주문 통합 관리")
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadOrders()
        }
        .sheet(isPresented: $showStartDatePicker) {
            DateRangePickerView(startDate: $viewModel.startDateObj, endDate: $viewModel.endDateObj) {
                viewModel.loadOrders()
            }
        }
    }
    
    private var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy.MM.dd"
        return "\(formatter.string(from: viewModel.startDateObj)) ~ \(formatter.string(from: viewModel.endDateObj))"
    }
}

// Separate View for Date Range Selection to avoid clutter
struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.dismiss) var dismiss
    var onApply: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("시작일", selection: $startDate, displayedComponents: .date)
                DatePicker("종료일", selection: $endDate, displayedComponents: .date)
            }
            .navigationTitle("기간 선택")
            .navigationBarItems(trailing: Button("적용") {
                onApply()
                dismiss()
            })
        }
    }
}

struct OrderMgtRow: View {
    let order: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Branch Name with Badge style
                Text(order["BRANCH_NAME"] as? String ?? order["branchName"] as? String ?? order["USER_NM"] as? String ?? order["userNm"] as? String ?? "지점 미지정")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                
                Spacer()
                
                // Status mapping with color
                Text(order["ORDER_STATUS_NM"] as? String ?? order["orderStatusNm"] as? String ?? "")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(statusColor)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text(order["ORDER_DATE"] as? String ?? order["ORDERED_AT"] as? String ?? "")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("주문번호:")
                        .foregroundColor(.secondary)
                    Text("\(order["ORDER_NO"] as? String ?? "")")
                        .fontWeight(.medium)
                }
                .font(.system(size: 14))
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("결제금액")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text(formatCurrency(order["TOTAL_PAY_AMOUNT"] ?? order["SUPPLY_PRICE_SUM"] ?? 0))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private var statusColor: Color {
        let status = (order["ORDER_STATUS"] ?? order["orderStatus"]).asString()
        switch status {
        case "10": return .red      // 결제대기
        case "30": return .blue     // 결제완료
        case "40": return .gray     // 주문취소
        case "50": return .orange   // 배송준비
        case "60": return .cyan     // 배송중
        case "70": return .green    // 배송완료
        case "99": return .indigo   // 주문확정
        default: return .gray
        }
    }
    
    private func formatCurrency(_ value: Any) -> String {
        let rawVal = String(describing: value)
        let amt = Int(rawVal.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: amt)) ?? "0원"
    }
}
