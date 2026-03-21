import Foundation

// MARK: - Order Creation
struct OrderCreateRequest: Encodable {
    let userNo: Int64
    let totalItemAmount: Int
    let deliveryFee: Int
    let discountAmount: Int
    let totalPayAmount: Int
    let receiverName: String
    let receiverPhone: String
    let zipCode: String
    let address1: String
    let address2: String
    let orderMemo: String
    let branchId: Int64?
    let items: [OrderItemRequest]
}

struct OrderItemRequest: Encodable {
    let productId: Int64
    let quantity: Int
    let optionName: String?
}

struct OrderCreateResponse: Decodable {
    let success: Bool
    let orderId: Int64
    let orderNo: String
    let amount: Int
    let orderName: String
    let message: String?
}

// MARK: - Payment Confirmation
struct PaymentConfirmRequest: Encodable {
    let paymentKey: String
    let orderNo: String
    let amount: Int
    let userNo: Int64?
}

struct PaymentConfirmResponse: Decodable {
    let success: Bool
    let message: String?
}

// MARK: - Order Cancellation
struct OrderCancelRequest: Encodable {
    let orderId: String
    let cancelReason: String
    let userNo: Int64
}

struct PaymentCancelRequest: Encodable {
    let paymentKey: String
    let orderId: String
    let amount: Int
}

struct PaymentCancelResponse: Decodable {
    let success: Bool
    let message: String?
}

// MARK: - Address Book
struct TbAddressBookVo: Codable, Identifiable {
    var id: Int64? { addressId }
    let addressId: Int64?
    let userNo: String?
    let recipientName: String?
    let recipientPhone: String?
    let zipCode: String?
    let addressMain: String?
    let addressDetail: String?
    let isDefault: Int?
    let memo: String?
}

// MARK: - Order Detail
struct OrderDetailResponse: Decodable {
    let items: [OrderDetailItem]
    let order: OrderInfo
}

struct OrderDetailItem: Decodable, Identifiable {
    var id: Int64 { orderItemId }
    let orderItemId: Int64
    let orderId: Int64
    let productId: Int64
    let productName: String
    let optionName: String?
    let unitPrice: Int
    let quantity: Int
    let imageUrl: String?
    let title: String?
}

struct OrderInfo: Decodable {
    let orderId: Int64
    let orderNo: String
    let userNo: Int64
    let orderStatus: String
    let orderStatusNm: String?
    let paymentStatus: String
    let totalItemAmount: Int
    let deliveryFee: Int
    let discountAmount: Int
    let totalPayAmount: Int
    let receiverName: String
    let receiverPhone: String
    let zipCode: String
    let address1: String
    let address2: String?
    let orderMemo: String?
    let orderedAt: String
    let paidAt: String?
    let cancelledAt: String?
    let deliveredAt: String?
}
