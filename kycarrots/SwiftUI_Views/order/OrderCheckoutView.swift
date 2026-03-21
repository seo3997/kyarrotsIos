import SwiftUI
import Combine
import Kingfisher

// MARK: - ViewModel
class OrderCheckoutViewModel: ObservableObject {
    @Published var product: ProductVo
    @Published var quantity: Int
    @Published var selectedOption: String?
    @Published var productImageUrl: String?  // ProductVo.imageUrl이 nil일 때 imageMetas에서 전달

    // 배송지 목록
    @Published var addresses: [TbAddressBookVo] = []
    @Published var selectedAddress: TbAddressBookVo?

    // 배송지 입력 폼
    @Published var recipientName: String = ""
    @Published var recipientPhone: String = ""
    @Published var zipCode: String = ""
    @Published var addressMain: String = ""
    @Published var addressDetail: String = ""
    @Published var orderMemo: String = ""
    @Published var saveAddress: Bool = false

    // 금액
    @Published var deliveryFee: Int = 0
    @Published var totalItemAmount: Int = 0
    @Published var totalPayAmount: Int = 0

    // 상태
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccess: Bool = false
    @Published var orderResult: OrderCreateResponse?
    @Published var showAddressPicker: Bool = false

    private let service: AppService

    init(product: ProductVo, quantity: Int, selectedOption: String?,
         productImageUrl: String? = nil,
         service: AppService = AppService(repo: RemoteRepository())) {
        self.product = product
        self.quantity = quantity
        self.selectedOption = selectedOption
        // ProductVo.imageUrl 우선, 없으면 imageMetas에서 넘긴 URL 사용
        self.productImageUrl = product.imageUrl ?? productImageUrl
        self.service = service
        calculateAmounts()
    }

    func calculateAmounts() {
        let cleanPrice = (product.price ?? "0").replacingOccurrences(of: ",", with: "")
        let price = Int(Double(cleanPrice) ?? 0)
        totalItemAmount = price * quantity

        let baseFee = LoginInfoUtil.getBaseShippingFee()
        let freeThreshold = LoginInfoUtil.getFreeShippingThreshold()

        // 안드로이드와 동일한 배송비 계산 로직 적용
        deliveryFee = (totalItemAmount >= freeThreshold) ? 0 : baseFee
        
        totalPayAmount = totalItemAmount + deliveryFee
    }

    func loadAddresses() {
        let token = TokenUtil.getToken()
        print("🔍 [iOS] loadAddresses 호출됨 - token: \(token)")
        guard !token.isEmpty else { return }
        Task {
            let list = await service.getAddressList(token: token)
            await MainActor.run {
                print("✅ [iOS] 배송지 목록 수신 성공 - 개수: \(list.count)")
                self.addresses = list
                // 기본 배송지 자동 적용
                if let def = list.first(where: { $0.isDefault == 1 }) {
                    self.applyAddress(def)
                } else if let first = list.first {
                    self.applyAddress(first)
                }
            }
        }
    }

    func showRecentAddresses() {
        print("🔍 [iOS] 최근 배송지 버튼 클릭됨")
        let token = TokenUtil.getToken()
        if token.isEmpty {
            self.errorMessage = "로그인이 필요합니다."
            return
        }
        
        Task {
            let list = await service.getAddressList(token: token)
            await MainActor.run {
                if !list.isEmpty {
                    print("✅ [iOS] 최근 배송지 로드 성공 - \(list.count)개")
                    self.addresses = list
                    self.showAddressPicker = true
                } else {
                    print("⚠️ [iOS] 저장된 배송지가 없습니다.")
                    self.errorMessage = "저장된 배송지가 없습니다."
                    self.addresses = []
                }
            }
        }
    }

    func applyAddress(_ addr: TbAddressBookVo) {
        selectedAddress = addr
        recipientName = addr.recipientName ?? ""
        recipientPhone = addr.recipientPhone ?? ""
        zipCode = addr.zipCode ?? ""
        addressMain = addr.addressMain ?? ""
        addressDetail = addr.addressDetail ?? ""
    }

    func formatPhone(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        let len = digits.count
        switch len {
        case 0...3: return digits
        case 4...7:
            if digits.hasPrefix("02") {
                return "\(digits.prefix(2))-\(digits.dropFirst(2))"
            }
            return "\(digits.prefix(3))-\(digits.dropFirst(3))"
        case 8...10:
            if digits.hasPrefix("02") {
                let mid = len == 10 ? 6 : 5
                return "\(digits.prefix(2))-\(digits.dropFirst(2).prefix(mid-2))-\(digits.suffix(len-mid))"
            }
            return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(3))-\(digits.suffix(len-6))"
        default:
            let s = String(digits.prefix(11))
            return "\(s.prefix(3))-\(s.dropFirst(3).prefix(4))-\(s.suffix(4))"
        }
    }

    func createOrder() {
        guard validate() else { return }

        isLoading = true
        let userNo = Int64(LoginInfoUtil.getUserNo()) ?? 0
        let branchId = Int64(LoginInfoUtil.getBranchId()) ?? 0
        let token = TokenUtil.getToken()

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

        Task {
            // 배송지 저장 체크 시 저장
            if saveAddress && !token.isEmpty {
                let addrVo = TbAddressBookVo(
                    addressId: nil, userNo: nil,
                    recipientName: recipientName,
                    recipientPhone: recipientPhone,
                    zipCode: zipCode,
                    addressMain: addressMain,
                    addressDetail: addressDetail,
                    isDefault: addresses.isEmpty ? 1 : 0,
                    memo: orderMemo
                )
                _ = await service.addAddress(token: token, address: addrVo)
            }

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
        if recipientName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "수령인 이름을 입력해주세요."; return false
        }
        if recipientPhone.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "연락처를 입력해주세요."; return false
        }
        if addressMain.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "주소를 검색해주세요."; return false
        }
        return true
    }
}

// MARK: - View
struct OrderCheckoutView: View {
    @StateObject var viewModel: OrderCheckoutViewModel
    @State private var showAddressSearch = false
    @State private var showPayConfirm = false

    var body: some View {
        ZStack {
            Color(hex: "F1F5F9").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // ── 1. 상품 정보 ──────────────────────────────
                    SectionCard {
                        HStack(spacing: 12) {
                            // 상품 이미지
                            Group {
                                if let urlStr = productImageUrl,
                                   let url = URL(string: urlStr) {
                                    KFImage(url)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    Color.gray.opacity(0.15)
                                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                                }
                            }
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                            .clipped()

                            VStack(alignment: .leading, spacing: 6) {
                                Text(viewModel.product.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .lineLimit(2)

                                if let opt = viewModel.selectedOption, !opt.isEmpty {
                                    Text("옵션: \(opt)")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }

                                Text("수량: \(viewModel.quantity)개")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                    }
                    .padding(.top, 12)

                    // ── 2. 배송지 ─────────────────────────────────
                    SectionCard(title: "배송지 정보") {
                        VStack(spacing: 10) {
                            // 버튼 Row
                            HStack(spacing: 8) {
                                // 최근 배송지 선택
                                OutlineButton(
                                    icon: "list.bullet",
                                    title: "최근 배송지",
                                    color: .blue
                                ) {
                                    viewModel.showRecentAddresses()
                                }

                                // 주소 검색
                                OutlineButton(
                                    icon: "magnifyingglass",
                                    title: "주소 검색",
                                    color: .orange
                                ) {
                                    showAddressSearch = true
                                }
                            }

                            Divider()

                            // 수령인
                            CheckoutField(label: "수령인", placeholder: "이름을 입력하세요",
                                          text: $viewModel.recipientName)

                            // 연락처 (자동 포맷)
                            CheckoutField(label: "연락처", placeholder: "010-0000-0000",
                                          text: $viewModel.recipientPhone,
                                          keyboardType: .phonePad)
                            .onChange(of: viewModel.recipientPhone) { newVal in
                                let formatted = viewModel.formatPhone(newVal)
                                if formatted != newVal {
                                    viewModel.recipientPhone = formatted
                                }
                            }

                            // 우편번호
                            CheckoutField(label: "우편번호", placeholder: "주소 검색",
                                          text: $viewModel.zipCode)
                            .disabled(true)

                            // 기본 주소
                            CheckoutField(label: "기본 주소", placeholder: "주소 검색",
                                          text: $viewModel.addressMain)
                            .disabled(true)

                            // 상세 주소
                            CheckoutField(label: "상세 주소", placeholder: "상세 주소를 입력하세요",
                                          text: $viewModel.addressDetail)

                            // 배송 메모
                            CheckoutField(label: "배송 메모", placeholder: "배송 시 요청사항 (선택)",
                                          text: $viewModel.orderMemo)

                            // 배송지 저장 체크박스
                            Toggle(isOn: $viewModel.saveAddress) {
                                Text("이 배송지를 저장하기")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .toggleStyle(CheckboxToggleStyle())
                            .padding(.top, 4)
                        }
                    }

                    // ── 3. 결제 금액 ──────────────────────────────
                    SectionCard(title: "결제 금액") {
                        VStack(spacing: 10) {
                            AmountRow(
                                label: "상품 금액 합계 (\(viewModel.quantity)개)",
                                value: viewModel.totalItemAmount,
                                bold: false
                            )
                            AmountRow(
                                label: "배송비",
                                value: viewModel.deliveryFee,
                                bold: false,
                                valueColor: viewModel.deliveryFee == 0 ? .blue : .primary
                            )

                            Divider()

                            HStack {
                                Text("최종 결제 금액")
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                                Text(formatCurrency(viewModel.totalPayAmount))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                        }
                    }

                    // ── 4. 결제하기 버튼 ──────────────────────────
                    Button(action: {
                        if viewModel.isLoading { return }
                        showPayConfirm = true
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange)
                                .frame(height: 54)
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("\(formatCurrency(viewModel.totalPayAmount)) 결제하기")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("주문서 작성")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .onAppear {
            viewModel.calculateAmounts()
            viewModel.loadAddresses()
        }
        // 주소 검색 시트
        .sheet(isPresented: $showAddressSearch) {
            AddressSearchView(onSelect: { addr in
                viewModel.zipCode = addr.zipCode
                viewModel.addressMain = addr.address
                showAddressSearch = false
            })
        }
        // 최근 배송지 상세 선택 시트 (주소, 전화번호 상세 노출)
        .sheet(isPresented: $viewModel.showAddressPicker) {
            NavigationView {
                List(viewModel.addresses) { addr in
                    Button {
                        viewModel.applyAddress(addr)
                        viewModel.showAddressPicker = false
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(addressLabel(addr))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("\(addr.addressMain ?? "") \(addr.addressDetail ?? "")")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("최근 배송지 선택")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("닫기") { viewModel.showAddressPicker = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        // 결제 확인 다이얼로그
        .alert("결제 확인", isPresented: $showPayConfirm) {
            Button("결제하기") { viewModel.createOrder() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("\(viewModel.product.title)\n\(formatCurrency(viewModel.totalPayAmount))에 결제하시겠습니까?")
        }
        // 에러 알림
        .alert("알림", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("확인") {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        // 결제 웹뷰
        .fullScreenCover(isPresented: $viewModel.showSuccess) {
            if let res = viewModel.orderResult {
                PaymentWebView(orderResponse: res) { success in
                    viewModel.showSuccess = false
                    // 결제 완료 후 성공 화면 이동은 PaymentWebView 내부에서 처리
                }
            }
        }
    }

    private func addressLabel(_ addr: TbAddressBookVo) -> String {
        let name = addr.recipientName ?? ""
        // 전화번호에 하이픈 추가
        let phone = viewModel.formatPhone(addr.recipientPhone ?? "")
        let def = addr.isDefault == 1 ? "[기본] " : ""
        return "\(def)\(name) (\(phone))"
    }

    private func formatCurrency(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "ko_KR")
        return f.string(from: NSNumber(value: value)) ?? "0원"
    }

    /// imageUrl이 쉼표 구분 문자열인 경우 첫 번째 URL만 추출
    private var productImageUrl: String? {
        // ViewModel에 명시적으로 전달된 URL이 있으면 우선 사용
        if let vmUrl = viewModel.productImageUrl, !vmUrl.isEmpty {
            return vmUrl
        }
        // ProductVo.imageUrl에 데이터가 있으면 파싱해서 사용
        guard let raw = viewModel.product.imageUrl, !raw.isEmpty else { return nil }
        return raw.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Reusable Sub-Components

/// 카드 섹션 래퍼
struct SectionCard<Content: View>: View {
    var title: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let t = title {
                Text(t)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
            }
            content()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
}

/// 아웃라인 버튼
struct OutlineButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 1.2)
            )
        }
    }
}

/// 입력 필드 (라벨 + TextField)
struct CheckoutField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .frame(width: 72, alignment: .leading)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .font(.system(size: 14))
                .padding(.vertical, 6)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.3)),
                    alignment: .bottom
                )
        }
    }
}

/// 금액 행
struct AmountRow: View {
    let label: String
    let value: Int
    var bold: Bool = false
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: bold ? .bold : .regular))
                .foregroundColor(bold ? .black : .gray)
            Spacer()
            Text(formattedValue)
                .font(.system(size: 14, weight: bold ? .bold : .medium))
                .foregroundColor(valueColor)
        }
    }

    private var formattedValue: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "ko_KR")
        return f.string(from: NSNumber(value: value)) ?? "0원"
    }
}

/// 체크박스 스타일 Toggle
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .orange : .gray)
                    .font(.system(size: 18))
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

/// PriceRow (하위 호환 유지용)
struct PriceRow: View {
    let label: String
    let value: Int

    var body: some View {
        AmountRow(label: label, value: value)
    }
}
