import SwiftUI
import Combine

class OrderMgtDetailViewModel: ObservableObject {
    @Published var order: [String: Any] = [:]
    @Published var items: [[String: Any]] = []
    @Published var carriers: [[String: Any]] = []
    
    @Published var selectedCarrierIndex: Int = 0
    @Published var trackingNo: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var actionSuccess: Bool = false
    
    private let service: AppService
    private let orderId: String
    
    init(orderId: String, service: AppService = AppService(repo: RemoteRepository())) {
        self.orderId = orderId
        self.service = service
    }
    
    func loadData() {
        Task {
            await loadDataAsync()
        }
    }

    func loadDataAsync() async {
        let token = TokenUtil.getToken()
        guard !token.isEmpty else { return }
        
        await MainActor.run { self.isLoading = true }
        
        if let data = await service.getOrderMgtDetail(orderId: orderId, token: token) {
            await MainActor.run {
                self.isLoading = false
                self.order = data["resultVo"] as? [String: Any] ?? [:]
                self.items = data["orderItemList"] as? [[String: Any]] ?? []
                self.carriers = data["deliveryCompanyList"] as? [[String: Any]] ?? []
                
                // Set current carrier
                let currentCode = (self.order["deliveryCompanyCode"] ?? "").asString()
                if let idx = self.carriers.firstIndex(where: { ($0["code"] ?? "").asString() == currentCode }) {
                    self.selectedCarrierIndex = idx + 1 // Account for "선택하세요"
                }
                
                self.trackingNo = (self.order["trackingNo"] ?? "").asString()
            }
        } else {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "상세 정보를 불러오지 못했습니다."
            }
        }
    }
    
    func performAction(_ type: String) {
        let token = TokenUtil.getToken()
        guard !token.isEmpty else { return }
        isLoading = true
        
        Task {
            var success = false
            switch type {
            case "DEPOSIT":
                guard selectedCarrierIndex > 0 else {
                    await showError("택배사를 선택해주세요.")
                    return
                }
                guard !trackingNo.isEmpty else {
                    await showError("송장 번호를 입력해주세요.")
                    return
                }
                let carrierCode = (carriers[selectedCarrierIndex - 1]["CODE"] ?? carriers[selectedCarrierIndex - 1]["code"]).asString()
                success = await service.confirmDeposit(token: token, orderId: orderId, carrier: carrierCode, tracking: trackingNo)
                
            case "BRANCH_DEPOSIT":
                success = await service.requestBranchDeposit(token: token, orderId: orderId)
                
            case "SHIPPING":
                guard selectedCarrierIndex > 0 else {
                    await showError("택배사를 선택해주세요.")
                    return
                }
                guard !trackingNo.isEmpty else {
                    await showError("송장 번호를 입력해주세요.")
                    return
                }
                let carrierCode = (carriers[selectedCarrierIndex - 1]["CODE"] ?? carriers[selectedCarrierIndex - 1]["code"]).asString()
                success = await service.updateShipping(token: token, orderId: orderId, carrier: carrierCode, tracking: trackingNo)
                
            case "DELIVERY":
                success = await service.updateOrderStatus(token: token, orderId: orderId, status: "70")
                
            case "CONFIRM":
                success = await service.updateOrderStatus(token: token, orderId: orderId, status: "99")
                
            case "CANCEL":
                let req = OrderCancelRequest(orderId: orderId, cancelReason: "관리자 취소", userNo: Int64(LoginInfoUtil.getUserNo()) ?? 0)
                success = await service.cancelPayment(req: req)
                
            default: break
            }
            
            await MainActor.run {
                if success {
                    self.actionSuccess = true
                    Task {
                        await self.loadDataAsync()
                        self.isLoading = false
                    }
                } else {
                    self.isLoading = false
                    self.errorMessage = "작업 수행에 실패했습니다."
                }
            }
        }
    }
    
    private func showError(_ msg: String) async {
        await MainActor.run {
            self.isLoading = false
            self.errorMessage = msg
        }
    }
}

struct OrderMgtDetailView: View {
    @StateObject var viewModel: OrderMgtDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    init(orderId: String) {
        _viewModel = StateObject(wrappedValue: OrderMgtDetailViewModel(orderId: orderId))
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F1F5F9").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Toolbar)
                VStack(spacing: 0) {
                    Spacer().frame(height: 44) // StatusBar area spacer (usually 44 on iPhones)
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Text("주문 상세 관리")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                        Color.clear.frame(width: 24)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                }
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                
                ScrollView {
                    VStack(spacing: 12) {
                        // 1. Order Basic Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text(statusNm)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.blue)
                            Text("주문번호: \(orderNo)")
                                .font(.system(size: 18, weight: .bold))
                            Text("주문일시: \(orderDate)")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                        
                        // 2. Management Actions Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📦 관리가능 처리")
                                .font(.system(size: 17, weight: .bold))
                            
                            if canConfirmDeposit {
                                DetailActionButton(label: "입금 확인 (발송시작가능)", color: Color(hex: "4F46E5")) {
                                    viewModel.performAction("DEPOSIT")
                                }
                            }
                            
                            if canRequestDeposit {
                                DetailActionButton(label: "본사 입금 확인 요청", color: Color(hex: "8B5CF6")) {
                                    viewModel.performAction("BRANCH_DEPOSIT")
                                }
                            }
                            
                            if canInputShipping {
                                VStack(spacing: 12) {
                                    // Carrier Spinner Replacement
                                    Menu {
                                        Picker("택배사", selection: $viewModel.selectedCarrierIndex) {
                                            Text("선택하세요").tag(0)
                                            ForEach(0..<viewModel.carriers.count, id: \.self) { idx in
                                                Text(viewModel.carriers[idx]["CODE_NM"] as? String ?? "").tag(idx + 1)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(viewModel.selectedCarrierIndex > 0 ? (viewModel.carriers[viewModel.selectedCarrierIndex - 1]["CODE_NM"] as? String ?? "") : "선택하세요")
                                                .font(.system(size: 15))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.down").font(.system(size: 12))
                                        }
                                        .padding()
                                        .background(Color(hex: "F8FAFC"))
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "E2E8F0")))
                                    }
                                    
                                    TextField("운송장 번호", text: $viewModel.trackingNo)
                                        .font(.system(size: 15))
                                        .keyboardType(.numberPad)
                                        .padding()
                                        .background(Color(hex: "F8FAFC"))
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "E2E8F0")))
                                    
                                    DetailActionButton(label: "배송 정보 업데이트", color: Color(hex: "10B981")) {
                                        viewModel.performAction("SHIPPING")
                                    }
                                }
                            }
                            
                            if canConfirmDelivery {
                                DetailActionButton(label: "배송 완료 처리", color: Color(hex: "F59E0B")) {
                                    viewModel.performAction("DELIVERY")
                                }
                            }
                            
                            if canConfirmOrder {
                                DetailActionButton(label: "주문 확정 처리", color: Color(hex: "6366F1")) {
                                    viewModel.performAction("CONFIRM")
                                }
                            }
                            
                            if canCancel {
                                DetailActionButton(label: "주문 취소", color: Color(hex: "EF4444")) {
                                    viewModel.performAction("CANCEL")
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                        
                        // 3. Customer & Shipping Info Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📋 주문 및 배송 정보")
                                .font(.system(size: 17, weight: .bold))
                            
                            Text("주문자: \(buyerInfo)")
                                .font(.system(size: 15))
                            Text("주소: \(address)")
                                .font(.system(size: 15))
                            Text("배송메모: \(memo)")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                        
                        // 4. Product Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("📦 상품 목록")
                                .font(.system(size: 17, weight: .bold))
                            
                            ForEach(viewModel.items, id: \.self.description) { item in
                                DetailItemRow(item: item)
                                if item.description != viewModel.items.last?.description {
                                    Divider()
                                }
                            }
                            
                            Divider().padding(.top, 4)
                            
                            HStack {
                                Text("총 결제 금액")
                                    .font(.system(size: 17, weight: .bold))
                                Spacer()
                                Text(totalAmount)
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                        .padding(.bottom, 40)
                    }
                    .padding(16)
                }
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.2).ignoresSafeArea()
                ProgressView()
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // MARK: - Helpers
    private var orderNo: String { (viewModel.order["orderNo"] ?? "").asString() }
    private var orderDate: String { (viewModel.order["orderedAt"] ?? viewModel.order["orderDate"] ?? "").asString() }
    private var statusNm: String {
        let s = (viewModel.order["orderStatusNm"] ?? "").asString()
        let d = (viewModel.order["branchDepositStatusNm"] ?? "").asString()
        if s.isEmpty {
             return (viewModel.order["orderStatus"] ?? "").asString()
        }
        return d.isEmpty ? s : "\(s) (\(d))"
    }
    private var buyerInfo: String { 
        let name = (viewModel.order["receiverName"] ?? viewModel.order["userNm"] ?? viewModel.order["branchName"] ?? "").asString()
        let phone = (viewModel.order["receiverPhone"] ?? viewModel.order["telNo"] ?? viewModel.order["phone"] ?? "").asString()
        return name.isEmpty ? "미지정" : "\(name) (\(phone))"
    }
    private var address: String {
        let zip = (viewModel.order["zipCode"] ?? "").asString()
        let a1 = (viewModel.order["address1"] ?? "").asString()
        let a2 = (viewModel.order["address2"] ?? "").asString()
        return zip.isEmpty ? "\(a1) \(a2)" : "(\(zip)) \(a1) \(a2)"
    }
    private var memo: String { 
        let m = (viewModel.order["orderMemo"] ?? "없음").asString()
        return m.isEmpty ? "없음" : m 
    }
    private var carrierInfo: String {
        let carrier = (viewModel.order["DELIVERY_COMPANY_NM"] ?? viewModel.order["deliveryCompanyNm"] ?? "").asString()
        let tracking = (viewModel.order["TRACKING_NO"] ?? viewModel.order["trackingNo"] ?? "").asString()
        if carrier.isEmpty && tracking.isEmpty { return "" }
        return "\(carrier) (\(tracking))"
    }
    private var totalAmount: String {
        let amt = Int(String(describing: viewModel.order["TOTAL_PAY_AMOUNT"] ?? viewModel.order["totalPayAmount"] ?? 0)) ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: amt)) ?? "0원"
    }
    
    // MARK: - Permissions
    private var role: String { LoginInfoUtil.getMemberCode() }
    private var status: String { (viewModel.order["ORDER_STATUS"] ?? viewModel.order["orderStatus"] ?? "").asString() }
    private var branchDepositStatus: String { (viewModel.order["BRANCH_DEPOSIT_STATUS"] ?? viewModel.order["branchDepositStatus"] ?? "").asString() }
    
    private var isHQOrAdmin: Bool { role == Constants.ROLE_ADMIN || role == Constants.ROLE_SELL }
    private var canInputShipping: Bool { isHQOrAdmin && ["30", "50", "60"].contains(status) }
    private var canConfirmDeposit: Bool { isHQOrAdmin && (branchDepositStatus == "10" || branchDepositStatus == "20") }
    private var canUpdateShipping: Bool { isHQOrAdmin && branchDepositStatus == "30" }
    private var canRequestDeposit: Bool { role == Constants.ROLE_PROJ && (branchDepositStatus == "10" || branchDepositStatus == "20") }
    private var canConfirmDelivery: Bool { isHQOrAdmin && status == "60" }
    private var canConfirmOrder: Bool { role == Constants.ROLE_PROJ && status == "70" }
    private var canCancel: Bool { status != "40" && role != Constants.ROLE_SELL }
}

struct DetailActionButton: View {
    let label: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(color)
                .cornerRadius(8)
        }
    }
}

struct DetailItemRow: View {
    let item: [String: Any]
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text((item["PRODUCT_NAME"] ?? item["productName"] ?? item["TITLE"] ?? "") as? String ?? "")
                    .font(.system(size: 16, weight: .medium))
                Text("\(Int(String(describing: item["QUANTITY"] ?? item["quantity"] ?? 0)) ?? 0)개")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(formattedPrice)
                .font(.system(size: 16, weight: .bold))
        }
        .padding(.vertical, 4)
    }
    private var formattedPrice: String {
        let qty = Int(String(describing: item["QUANTITY"] ?? item["quantity"] ?? 0)) ?? 0
        let price = Int(String(describing: item["UNIT_PRICE"] ?? item["unitPrice"] ?? 0)) ?? 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: qty * price)) ?? "0원"
    }
}
