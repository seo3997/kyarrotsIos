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
        let token = TokenUtil.getToken()
        guard !token.isEmpty else { return }
        isLoading = true
        
        Task {
            if let data = await service.getOrderMgtDetail(orderId: orderId, token: token) {
                await MainActor.run {
                    self.isLoading = false
                    self.order = data["resultVo"] as? [String: Any] ?? [:]
                    self.items = data["orderItemList"] as? [[String: Any]] ?? []
                    self.carriers = data["deliveryCompanyList"] as? [[String: Any]] ?? []
                    
                    // Set current carrier
                    let currentCode = (self.order["DELIVERY_COMPANY_CODE"] ?? self.order["deliveryCompanyCode"]).asString()
                    if let idx = self.carriers.firstIndex(where: { ($0["CODE"] ?? $0["code"]).asString() == currentCode }) {
                        self.selectedCarrierIndex = idx + 1 // Account for "선택하세요"
                    }
                    
                    self.trackingNo = (self.order["TRACKING_NO"] ?? self.order["trackingNo"]).asString()
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "상세 정보를 불러오지 못했습니다."
                }
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
                let carrierCode = carriers[selectedCarrierIndex - 1]["CODE"] as? String ?? ""
                success = await service.confirmDeposit(token: token, orderId: orderId, carrier: carrierCode, tracking: trackingNo)
                
            case "BRANCH_DEPOSIT":
                success = await service.requestBranchDeposit(token: token, orderId: orderId)
                
            case "SHIPPING":
                let carrierCode = selectedCarrierIndex > 0 ? (carriers[selectedCarrierIndex - 1]["CODE"] as? String ?? "") : ""
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
                self.isLoading = false
                if success {
                    self.actionSuccess = true
                    self.loadData()
                } else {
                    self.errorMessage = "작전 수행에 실패했습니다."
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
            Color(hex: "F8F9FA").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Status Badge
                    HStack {
                        Text(statusNm)
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                        Spacer()
                        Text(orderNo)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // Order Info
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "주문 일시", value: orderDate)
                        InfoRow(label: "주문자", value: buyerInfo)
                        InfoRow(label: "배송 주소", value: address)
                        InfoRow(label: "배송 메모", value: memo)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // Shipping Input (VISIBLE only for HQ/Admin and specific statuses)
                    if isHQOrAdmin && canInputShipping {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("배송 정보 입력")
                                .font(.headline)
                            
                            Picker("택배사", selection: $viewModel.selectedCarrierIndex) {
                                Text("선택하세요").tag(0)
                                ForEach(0..<viewModel.carriers.count, id: \.self) { idx in
                                    Text(viewModel.carriers[idx]["CODE_NM"] as? String ?? "").tag(idx + 1)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color(hex: "F1F5F9"))
                            .cornerRadius(8)
                            
                            TextField("송장 번호 입력", text: $viewModel.trackingNo)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color(hex: "F1F5F9"))
                                .cornerRadius(8)
                            
                            HStack {
                                if canConfirmDeposit {
                                    ActionButton(label: "입금 확인 및 발송", color: .orange) {
                                        viewModel.performAction("DEPOSIT")
                                    }
                                }
                                if canUpdateShipping {
                                    ActionButton(label: "배송 정보 수정", color: .blue) {
                                        viewModel.performAction("SHIPPING")
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    
                    // Item List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("주문 상품")
                            .font(.headline)
                        
                        ForEach(viewModel.items, id: \.self.description) { item in
                            ItemRow(item: item)
                            Divider()
                        }
                        
                        HStack {
                            Text("총 결제 금액")
                                .font(.headline)
                            Spacer()
                            Text(totalAmount)
                                .font(.title3.bold())
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // Primary Actions
                    VStack(spacing: 12) {
                        if canRequestDeposit {
                            ActionButton(label: "본사 송금 확인 요청", color: .blue) {
                                viewModel.performAction("BRANCH_DEPOSIT")
                            }
                        }
                        
                        if canConfirmDelivery {
                            ActionButton(label: "배송 완료 처리", color: .green) {
                                viewModel.performAction("DELIVERY")
                            }
                        }
                        
                        if canConfirmOrder {
                            ActionButton(label: "주문 확정 처리", color: .orange) {
                                viewModel.performAction("CONFIRM")
                            }
                        }
                        
                        if canCancel {
                            ActionButton(label: "주문 취소", color: .red) {
                                viewModel.performAction("CANCEL")
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.1).ignoresSafeArea()
                ProgressView()
            }
        }
        .navigationTitle("주문 상세 관리")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadData()
        }
        .alert("결과", isPresented: $viewModel.actionSuccess) {
            Button("확인") { viewModel.actionSuccess = false }
        } message: {
            Text("처리가 완료되었습니다.")
        }
        .alert("오류", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
            Button("확인") { }
        } message: {
            if let msg = viewModel.errorMessage { Text(msg) }
        }
    }
    
    // MARK: - Helpers
    private var orderNo: String { (viewModel.order["ORDER_NO"] ?? viewModel.order["orderNo"]).asString() }
    private var orderDate: String { (viewModel.order["ORDERED_AT"] ?? viewModel.order["orderDate"] ?? "").asString() }
    private var statusNm: String { (viewModel.order["ORDER_STATUS_NM"] ?? viewModel.order["orderStatusNm"]).asString() }
    private var buyerInfo: String { 
        let name = (viewModel.order["RECEIVER_NAME"] ?? viewModel.order["USER_NM"] ?? "").asString()
        let phone = (viewModel.order["RECEIVER_PHONE"] ?? viewModel.order["TEL_NO"] ?? "").asString()
        return "\(name) (\(phone))"
    }
    private var address: String {
        let zip = (viewModel.order["ZIP_CODE"] ?? viewModel.order["zipCode"]).asString()
        let a1 = (viewModel.order["ADDRESS1"] ?? viewModel.order["address1"]).asString()
        let a2 = (viewModel.order["ADDRESS2"] ?? viewModel.order["address2"]).asString()
        return "(\(zip)) \(a1) \(a2)"
    }
    private var memo: String { 
        let m = (viewModel.order["ORDER_MEMO"] ?? viewModel.order["orderMemo"]).asString()
        return m.isEmpty ? "없음" : m 
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
    private var status: String { (viewModel.order["ORDER_STATUS"] ?? viewModel.order["orderStatus"]).asString() }
    private var branchDepositStatus: String { (viewModel.order["BRANCH_DEPOSIT_STATUS"] ?? viewModel.order["branchDepositStatus"]).asString() }
    
    private var isHQOrAdmin: Bool { role == Constants.ROLE_ADMIN || role == Constants.ROLE_SELL }
    private var canInputShipping: Bool { isHQOrAdmin && ["30", "50", "60"].contains(status) }
    private var canConfirmDeposit: Bool { isHQOrAdmin && (branchDepositStatus == "10" || branchDepositStatus == "20") }
    private var canUpdateShipping: Bool { isHQOrAdmin && branchDepositStatus == "30" }
    private var canRequestDeposit: Bool { role == Constants.ROLE_PROJ && (branchDepositStatus == "10" || branchDepositStatus == "20") }
    private var canConfirmDelivery: Bool { isHQOrAdmin && status == "60" }
    private var canConfirmOrder: Bool { role == Constants.ROLE_PROJ && status == "70" }
    private var canCancel: Bool { status != "40" && role != Constants.ROLE_SELL }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .top) {
            Text(label).font(.system(size: 13)).foregroundColor(.gray).frame(width: 80, alignment: .leading)
            Text(value).font(.system(size: 13, weight: .medium)).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ItemRow: View {
    let item: [String: Any]
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text((item["PRODUCT_NAME"] ?? item["productName"] ?? "") as? String ?? "").font(.system(size: 14, weight: .bold))
            HStack {
                Text("\(Int(String(describing: item["QUANTITY"] ?? item["quantity"] ?? 0)) ?? 0)개")
                Spacer()
                Text(formattedPrice)
            }
            .font(.system(size: 13))
            .foregroundColor(.gray)
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

struct ActionButton: View {
    let label: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.system(size: 16, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 50).background(color).cornerRadius(10)
        }
    }
}
