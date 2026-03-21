import SwiftUI
import Combine

class OrderDetailViewModel: ObservableObject {
    @Published var order: OrderInfo?
    @Published var items: [OrderDetailItem] = []
    
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
        isLoading = true
        
        Task {
            if let response = await service.getOrderDetail(orderId: orderId) {
                await MainActor.run {
                    self.isLoading = false
                    self.order = response.order
                    self.items = response.items
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "상세 정보를 불러오지 못했습니다."
                }
            }
        }
    }
    
    func cancelOrder() {
        isLoading = true
        let userNo = Int64(LoginInfoUtil.getUserNo()) ?? 0
        let req = OrderCancelRequest(orderId: orderId, cancelReason: "사용자 취소", userNo: userNo)
        
        Task {
            let success = await service.cancelPayment(req: req)
            await MainActor.run {
                self.isLoading = false
                if success {
                    self.actionSuccess = true
                    self.loadData()
                } else {
                    self.errorMessage = "주문 취소에 실패했습니다."
                }
            }
        }
    }
}

struct OrderDetailView: View {
    @StateObject var viewModel: OrderDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    init(orderId: String) {
        _viewModel = StateObject(wrappedValue: OrderDetailViewModel(orderId: orderId))
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F8F9FA").ignoresSafeArea()
            
            if let order = viewModel.order {
                ScrollView {
                    VStack(spacing: 16) {
                        // Status Badge
                        HStack {
                            Text(order.orderStatusNm ?? "알 수 없음")
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(8)
                            Spacer()
                            Text(order.orderNo)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Order Info
                        VStack(alignment: .leading, spacing: 12) {
                            BuyerInfoRow(label: "주문 일시", value: order.orderedAt)
                            BuyerInfoRow(label: "배송 주소", value: "(\(order.zipCode)) \(order.address1) \(order.address2 ?? "")")
                            BuyerInfoRow(label: "배송 메모", value: order.orderMemo ?? "없음")
                            BuyerInfoRow(label: "수령인", value: "\(order.receiverName) (\(order.receiverPhone))")
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Item List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("주문 상품")
                                .font(.headline)
                            
                            ForEach(viewModel.items, id: \.id) { item in
                                BuyerItemRow(item: item)
                                Divider()
                            }
                            
                            HStack {
                                Text("결제 금액")
                                    .font(.headline)
                                Spacer()
                                Text(formatCurrency(order.totalPayAmount))
                                    .font(.title3.bold())
                                    .foregroundColor(.orange)
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Primary Actions
                        if ["10", "20"].contains(order.orderStatus) {
                            VStack(spacing: 12) {
                                Button(action: {
                                    viewModel.cancelOrder()
                                }) {
                                    Text("주문 취소")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.red)
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                    .padding()
                }
            } else if !viewModel.isLoading {
                VStack {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                    Text("주문 정보를 찾을 수 없습니다.")
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.1).ignoresSafeArea()
                ProgressView()
            }
        }
        .navigationTitle("주문 상세 내역")
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
    
    private func formatCurrency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: value)) ?? "0원"
    }
}

struct BuyerInfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .top) {
            Text(label).font(.system(size: 13)).foregroundColor(.gray).frame(width: 80, alignment: .leading)
            Text(value).font(.system(size: 13, weight: .medium)).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct BuyerItemRow: View {
    let item: OrderDetailItem
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.productName).font(.system(size: 14, weight: .bold))
            if let opt = item.optionName, !opt.isEmpty {
                Text("옵션: \(opt)").font(.system(size: 12)).foregroundColor(.gray)
            }
            HStack {
                Text("\(item.quantity)개")
                Spacer()
                Text(formatCurrency(item.quantity * item.unitPrice))
            }
            .font(.system(size: 13))
            .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: value)) ?? "0원"
    }
}
