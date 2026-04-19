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
    let productName: String?
}

struct OrderCreateResponse: Decodable {
    let success: Bool
    let orderId: Int64
    let orderNo: String
    let amount: Int
    let orderName: String?
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

struct OrderReturnRequest: Encodable {
    let orderId: String
    let returnReason: String
    let userNo: Int64
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
        
        // Lowercase / Snake case variations
        case addressIdLower = "address_id"
        case userNoLower = "user_no"
        case recipientNameLower = "recipient_name"
        case recipientPhoneLower = "recipient_phone"
        case zipCodeLower = "zip_code"
        case addressMainLower = "address_main"
        case addressDetailLower = "address_detail"
        case isDefaultLower = "is_default"
        case memoLower = "memo"
        
        // Camel case variations
        case addressIdCamel = "addressId"
        case userNoCamel = "userNo"
        case recipientNameCamel = "recipientName"
        case recipientPhoneCamel = "recipientPhone"
        case zipCodeCamel = "zipCode"
        case addressMainCamel = "addressMain"
        case addressDetailCamel = "addressDetail"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // addressId
        if let val = try? container.decode(Int64.self, forKey: .addressId) { addressId = val }
        else if let val = try? container.decode(Int64.self, forKey: .addressIdLower) { addressId = val }
        else if let val = try? container.decode(Int64.self, forKey: .addressIdCamel) { addressId = val }
        else if let val = try? container.decode(Int.self, forKey: .addressId) { addressId = Int64(val) }
        else if let val = try? container.decode(Int.self, forKey: .addressIdLower) { addressId = Int64(val) }
        else if let val = try? container.decode(Int.self, forKey: .addressIdCamel) { addressId = Int64(val) }
        else if let str = try? container.decode(String.self, forKey: .addressId), let val = Int64(str) { addressId = val }
        else if let str = try? container.decode(String.self, forKey: .addressIdLower), let val = Int64(str) { addressId = val }
        else if let str = try? container.decode(String.self, forKey: .addressIdCamel), let val = Int64(str) { addressId = val }
        else { addressId = nil }
        
        // userNo
        if let val = try? container.decode(String.self, forKey: .userNo) { userNo = val }
        else if let val = try? container.decode(String.self, forKey: .userNoLower) { userNo = val }
        else if let val = try? container.decode(String.self, forKey: .userNoCamel) { userNo = val }
        else if let val = try? container.decode(Int.self, forKey: .userNo) { userNo = String(val) }
        else if let val = try? container.decode(Int.self, forKey: .userNoLower) { userNo = String(val) }
        else if let val = try? container.decode(Int.self, forKey: .userNoCamel) { userNo = String(val) }
        else { userNo = nil }
        
        recipientName = (try? container.decode(String.self, forKey: .recipientName)) ?? (try? container.decode(String.self, forKey: .recipientNameLower)) ?? (try? container.decode(String.self, forKey: .recipientNameCamel))
        recipientPhone = (try? container.decode(String.self, forKey: .recipientPhone)) ?? (try? container.decode(String.self, forKey: .recipientPhoneLower)) ?? (try? container.decode(String.self, forKey: .recipientPhoneCamel))
        zipCode = (try? container.decode(String.self, forKey: .zipCode)) ?? (try? container.decode(String.self, forKey: .zipCodeLower)) ?? (try? container.decode(String.self, forKey: .zipCodeCamel))
        addressMain = (try? container.decode(String.self, forKey: .addressMain)) ?? (try? container.decode(String.self, forKey: .addressMainLower)) ?? (try? container.decode(String.self, forKey: .addressMainCamel))
        addressDetail = (try? container.decode(String.self, forKey: .addressDetail)) ?? (try? container.decode(String.self, forKey: .addressDetailLower)) ?? (try? container.decode(String.self, forKey: .addressDetailCamel))
        
        // isDefault
        if let val = try? container.decode(Bool.self, forKey: .isDefault) { isDefault = val ? 1 : 0 }
        else if let val = try? container.decode(Bool.self, forKey: .isDefaultLower) { isDefault = val ? 1 : 0 }
        else if let val = try? container.decode(Int.self, forKey: .isDefault) { isDefault = val }
        else if let val = try? container.decode(Int.self, forKey: .isDefaultLower) { isDefault = val }
        else { isDefault = 0 }
        
        memo = (try? container.decode(String.self, forKey: .memo)) ?? (try? container.decode(String.self, forKey: .memoLower))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(addressId, forKey: .addressId)
        try container.encodeIfPresent(userNo, forKey: .userNo)
        try container.encodeIfPresent(recipientName, forKey: .recipientName)
        try container.encodeIfPresent(recipientPhone, forKey: .recipientPhone)
        try container.encodeIfPresent(zipCode, forKey: .zipCode)
        try container.encodeIfPresent(addressMain, forKey: .addressMain)
        try container.encodeIfPresent(addressDetail, forKey: .addressDetail)
        try container.encodeIfPresent(isDefault, forKey: .isDefault)
        try container.encodeIfPresent(memo, forKey: .memo)
    }
    
    init(addressId: Int64? = nil, userNo: String? = nil, recipientName: String? = nil, recipientPhone: String? = nil, zipCode: String? = nil, addressMain: String? = nil, addressDetail: String? = nil, isDefault: Int? = 0, memo: String? = nil) {
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

struct AddressListResponse: Decodable {
    let list: [TbAddressBookVo]?
    let data: [TbAddressBookVo]?
    let items: [TbAddressBookVo]?
    
    var addresses: [TbAddressBookVo] {
        list ?? data ?? items ?? []
    }
    
    enum CodingKeys: String, CodingKey {
        case list, data, items
    }
    
    init(from decoder: Decoder) throws {
        // 배열 직접 디코딩 시도
        if let array = try? decoder.singleValueContainer().decode([TbAddressBookVo].self) {
            self.list = array
            self.data = nil
            self.items = nil
            return
        }
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.list = try? container.decode([TbAddressBookVo].self, forKey: .list)
        self.data = try? container.decode([TbAddressBookVo].self, forKey: .data)
        self.items = try? container.decode([TbAddressBookVo].self, forKey: .items)
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
