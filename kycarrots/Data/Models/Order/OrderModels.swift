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

    enum CodingKeys: String, CodingKey {
        case addressId = "ADDRESS_ID"
        case userNo = "USER_NO"
        case recipientName = "RECIPIENT_NAME"
        case recipientPhone = "RECIPIENT_PHONE"
        case zipCode = "ZIP_CODE"
        case addressMain = "ADDRESS_MAIN"
        case addressDetail = "ADDRESS_DETAIL"
        case isDefault = "IS_DEFAULT"
        case memo = "MEMO"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // addressId: Int64 or Int
        if let val = try? container.decode(Int64.self, forKey: .addressId) {
            addressId = val
        } else if let val = try? container.decode(Int.self, forKey: .addressId) {
            addressId = Int64(val)
        } else if let str = try? container.decode(String.self, forKey: .addressId), let val = Int64(str) {
            addressId = val
        } else {
            addressId = nil
        }
        
        // userNo: String or Int
        if let val = try? container.decode(String.self, forKey: .userNo) {
            userNo = val
        } else if let val = try? container.decode(Int.self, forKey: .userNo) {
            userNo = String(val)
        } else {
            userNo = nil
        }
        
        recipientName = try? container.decode(String.self, forKey: .recipientName)
        recipientPhone = try? container.decode(String.self, forKey: .recipientPhone)
        zipCode = try? container.decode(String.self, forKey: .zipCode)
        addressMain = try? container.decode(String.self, forKey: .addressMain)
        addressDetail = try? container.decode(String.self, forKey: .addressDetail)
        
        // isDefault: Bool or Int
        if let val = try? container.decode(Bool.self, forKey: .isDefault) {
            isDefault = val ? 1 : 0
        } else if let val = try? container.decode(Int.self, forKey: .isDefault) {
            isDefault = val
        } else {
            isDefault = 0
        }
        
        memo = try? container.decode(String.self, forKey: .memo)
    }
    
    // 수동 생성자 (커스텀 init(from:) 추가 시 자동 생성자가 소멸되므로 직접 추가)
    init(addressId: Int64? = nil,
         userNo: String? = nil,
         recipientName: String? = nil,
         recipientPhone: String? = nil,
         zipCode: String? = nil,
         addressMain: String? = nil,
         addressDetail: String? = nil,
         isDefault: Int? = 0,
         memo: String? = nil) {
        self.addressId = addressId
        self.userNo = userNo
        self.recipientName = recipientName
        self.recipientPhone = recipientPhone
        self.zipCode = zipCode
        self.addressMain = addressMain
        self.addressDetail = addressDetail
        self.isDefault = isDefault
        self.memo = memo
    }
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
