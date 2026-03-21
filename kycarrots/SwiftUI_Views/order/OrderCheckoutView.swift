import SwiftUI
import Combine

class OrderCheckoutViewModel: ObservableObject {
    @Published var product: ProductVo
    @Published var quantity: Int
    @Published var selectedOption: String?
    
    @Published var addresses: [TbAddressBookVo] = []
    @Published var selectedAddress: TbAddressBookVo?
    
    @Published var recipientName: String = ""
    @Published var recipientPhone: String = ""
    @Published var zipCode: String = ""
    @Published var addressMain: String = ""
    @Published var addressDetail: String = ""
    @Published var orderMemo: String = ""
    
    @Published var deliveryFee: Int = 0
    @Published var totalItemAmount: Int = 0
    @Published var totalPayAmount: Int = 0
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccess: Bool = false
    @Published var orderResult: OrderCreateResponse?
    
    private let service: AppService
    
    init(product: ProductVo, quantity: Int, selectedOption: String?, service: AppService = AppService(repo: RemoteRepository())) {
        self.product = product
        self.quantity = quantity
        self.selectedOption = selectedOption
        self.service = service
        
        calculateAmounts()
    }
    
    func calculateAmounts() {
        let price = Int(product.price ?? "0") ?? 0
        totalItemAmount = price * quantity
        
        // Android logic: if sale_type is '2', delivery fee is 0, else 3500 (if < 50000)
        // Wait! Let's check OrderActivity.kt line 150
        if product.systemType == "2" {
            deliveryFee = 0
        } else {
            deliveryFee = totalItemAmount >= 50000 ? 0 : 3500
        }
        
        totalPayAmount = totalItemAmount + deliveryFee
    }
    
    func loadAddresses() {
        let token = TokenUtil.getToken()
        guard !token.isEmpty else { return }
        isLoading = true
        Task {
            let list = await service.getAddressList(token: token)
            await MainActor.run {
                self.addresses = list
                if let def = list.first(where: { $0.isDefault == 1 }) {
                    self.setAddress(def)
                } else if let first = list.first {
                    self.setAddress(first)
                }
                self.isLoading = false
            }
        }
    }
    
    func setAddress(_ addr: TbAddressBookVo) {
        selectedAddress = addr
        recipientName = addr.recipientName ?? ""
        recipientPhone = addr.recipientPhone ?? ""
        zipCode = addr.zipCode ?? ""
        addressMain = addr.addressMain ?? ""
        addressDetail = addr.addressDetail ?? ""
    }
    
    func createOrder() {
        guard validate() else { return }
        
        let userNo = Int64(LoginInfoUtil.getUserNo()) ?? 0
        let branchId = Int64(LoginInfoUtil.getBranchId()) ?? 0
        
        let itemReq = OrderItemRequest(
            productId: Int64(product.productId ?? "0") ?? 0,
            quantity: quantity,
            optionName: selectedOption
        )
        
        let orderReq = OrderCreateRequest(
            userNo: userNo,
            totalItemAmount: totalItemAmount,
            deliveryFee: deliveryFee,
            discountAmount: 0,
            totalPayAmount: totalPayAmount,
            receiverName: recipientName,
            receiverPhone: recipientPhone,
            zipCode: zipCode,
            address1: addressMain,
            address2: addressDetail,
            orderMemo: orderMemo,
            branchId: branchId,
            items: [itemReq]
        )
        
        isLoading = true
        Task {
            if let res = await service.createOrder(req: orderReq) {
                await MainActor.run {
                    self.isLoading = false
                    if res.success {
                        self.orderResult = res
                        self.showSuccess = true
                    } else {
                        self.errorMessage = res.message ?? "주문 생성에 실패했습니다."
                    }
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "서버 통신에 실패했습니다."
                }
            }
        }
    }
    
    private func validate() -> Bool {
        if recipientName.isEmpty { errorMessage = "수령인을 입력해주세요."; return false }
        if recipientPhone.isEmpty { errorMessage = "연락처를 입력해주세요."; return false }
        if zipCode.isEmpty { errorMessage = "주소를 검색해주세요."; return false }
        return true
    }
}

struct OrderCheckoutView: View {
    @StateObject var viewModel: OrderCheckoutViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showAddressSearch = false
    @State private var showPaymentWeb = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F8F9FA").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Product Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("주문 상품")
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                if let url = productImageUrl {
                                    AsyncImage(url: url) { img in
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(8)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.product.title)
                                        .font(.system(size: 15, weight: .bold))
                                    
                                    if let opt = viewModel.selectedOption {
                                        Text("옵션: \(opt)")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text("\(viewModel.quantity)개")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                    
                                    Text(priceString)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.orange)
                                }
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Shipping Info
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("배송 정보")
                                    .font(.headline)
                                Spacer()
                                Button(action: { showAddressSearch = true }) {
                                    Text("주소 검색")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.orange)
                                        .cornerRadius(6)
                                }
                            }
                            
                            VStack(spacing: 12) {
                                OrderCustomTextField(label: "수령인", text: $viewModel.recipientName)
                                OrderCustomTextField(label: "연락처", text: $viewModel.recipientPhone, keyboardType: .phonePad)
                                
                                HStack {
                                    OrderCustomTextField(label: "우편번호", text: $viewModel.zipCode)
                                        .disabled(true)
                                    Spacer()
                                }
                                
                                OrderCustomTextField(label: "기본 주소", text: $viewModel.addressMain)
                                    .disabled(true)
                                
                                OrderCustomTextField(label: "상세 주소", text: $viewModel.addressDetail)
                                
                                OrderCustomTextField(label: "배송 메모", text: $viewModel.orderMemo)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Price Calculation
                        VStack(spacing: 12) {
                            Text("결제 금액")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            PriceRow(label: "총 상품 금액", value: viewModel.totalItemAmount)
                            PriceRow(label: "배송비", value: viewModel.deliveryFee)
                            
                            Divider()
                            
                            HStack {
                                Text("최종 결제 금액")
                                    .font(.system(size: 18, weight: .bold))
                                Spacer()
                                Text(totalPayString)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Submit Button
                        Button(action: {
                            viewModel.createOrder()
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("\(totalPayString) 결제하기")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.orange)
                        .cornerRadius(12)
                        .padding(.vertical, 20)
                    }
                    .padding()
                }
                
                if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(error)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            viewModel.errorMessage = nil
                        }
                    }
                }
            }
            .navigationTitle("주문서 작성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
                }
            }
            .onAppear {
                viewModel.loadAddresses()
            }
            .sheet(isPresented: $showAddressSearch) {
                AddressSearchView(onSelect: { addr in
                    viewModel.zipCode = addr.zipCode
                    viewModel.addressMain = addr.address
                    showAddressSearch = false
                })
            }
            .fullScreenCover(isPresented: $viewModel.showSuccess) {
                if let res = viewModel.orderResult {
                    PaymentWebView(orderResponse: res) { success in
                        viewModel.showSuccess = false
                        if success {
                            // Go to Success Screen
                        }
                    }
                }
            }
        }
    }
    
    private var productImageUrl: URL? {
        if let paths = viewModel.product.imageUrl, let first = paths.components(separatedBy: ",").first {
            return URL(string: first)
        }
        return nil
    }
    
    private var priceString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: Int(viewModel.product.price ?? "0") ?? 0)) ?? "0원"
    }
    
    private var totalPayString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: viewModel.totalPayAmount)) ?? "0원"
    }
}

struct PriceRow: View {
    let label: String
    let value: Int
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
            Text(formattedValue)
                .font(.system(size: 14, weight: .medium))
        }
    }
    
    private var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: value)) ?? "0원"
    }
}

struct OrderCustomTextField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            
            TextField("", text: $text)
                .keyboardType(keyboardType)
                .padding(.vertical, 8)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.3)),
                    alignment: .bottom
                )
        }
    }
}
