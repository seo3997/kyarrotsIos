import Foundation

struct BranchInfoVo: Codable {
    let branchId: Int64?
    let branchCode: String?
    let branchName: String?
    let logoImageUrl: String?
    let branchStatus: String?
    let companyName: String?
    let tossClientKey: String?
    let baseShippingFee: Int?
    let freeShippingThreshold: Int?
    
    enum CodingKeys: String, CodingKey {
        case branchId = "branchId"
        case branch_id = "branch_id"
        case BRANCH_ID = "BRANCH_ID"
        case branchCode = "branchCode"
        case branch_code = "branch_code"
        case BRANCH_CODE = "BRANCH_CODE"
        case branchName = "branchName"
        case branch_name = "branch_name"
        case BRANCH_NAME = "BRANCH_NAME"
        case logoImageUrl = "logoImageUrl"
        case logo_image_url = "logo_image_url"
        case LOGO_IMAGE_URL = "LOGO_IMAGE_URL"
        case branchStatus = "branchStatus"
        case branch_status = "branch_status"
        case BRANCH_STATUS = "BRANCH_STATUS"
        case companyName = "companyName"
        case company_name = "company_name"
        case COMPANY_NAME = "COMPANY_NAME"
        case tossClientKey = "tossClientKey"
        case toss_client_key = "toss_client_key"
        case TOSS_CLIENT_KEY = "TOSS_CLIENT_KEY"
        case baseShippingFee = "baseShippingFee"
        case base_shipping_fee = "base_shipping_fee"
        case BASE_SHIPPING_FEE = "BASE_SHIPPING_FEE"
        case freeShippingThreshold = "freeShippingThreshold"
        case free_shipping_threshold = "free_shipping_threshold"
        case FREE_SHIPPING_THRESHOLD = "FREE_SHIPPING_THRESHOLD"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // branchId: Int64 or String
        if let val = try? container.decode(Int64.self, forKey: .branchId) { branchId = val }
        else if let val = try? container.decode(Int64.self, forKey: .branch_id) { branchId = val }
        else if let val = try? container.decode(Int64.self, forKey: .BRANCH_ID) { branchId = val }
        else if let str = try? container.decode(String.self, forKey: .branchId), let v = Int64(str) { branchId = v }
        else if let str = try? container.decode(String.self, forKey: .branch_id), let v = Int64(str) { branchId = v }
        else if let str = try? container.decode(String.self, forKey: .BRANCH_ID), let v = Int64(str) { branchId = v }
        else { branchId = nil }

        branchCode = try? container.decode(String.self, forKey: .branchCode) ??
                     container.decode(String.self, forKey: .branch_code) ??
                     container.decode(String.self, forKey: .BRANCH_CODE)
        
        branchName = try? container.decode(String.self, forKey: .branchName) ??
                     container.decode(String.self, forKey: .branch_name) ??
                     container.decode(String.self, forKey: .BRANCH_NAME)
        
        logoImageUrl = try? container.decode(String.self, forKey: .logoImageUrl) ??
                       container.decode(String.self, forKey: .logo_image_url) ??
                       container.decode(String.self, forKey: .LOGO_IMAGE_URL)
        
        branchStatus = try? container.decode(String.self, forKey: .branchStatus) ??
                       container.decode(String.self, forKey: .branch_status) ??
                       container.decode(String.self, forKey: .BRANCH_STATUS)
        
        companyName = try? container.decode(String.self, forKey: .companyName) ??
                      container.decode(String.self, forKey: .company_name) ??
                      container.decode(String.self, forKey: .COMPANY_NAME)
        
        tossClientKey = try? container.decode(String.self, forKey: .tossClientKey) ??
                        container.decode(String.self, forKey: .toss_client_key) ??
                        container.decode(String.self, forKey: .TOSS_CLIENT_KEY)
        
        // baseShippingFee: Int or String
        if let val = try? container.decode(Int.self, forKey: .baseShippingFee) { baseShippingFee = val }
        else if let val = try? container.decode(Int.self, forKey: .base_shipping_fee) { baseShippingFee = val }
        else if let val = try? container.decode(Int.self, forKey: .BASE_SHIPPING_FEE) { baseShippingFee = val }
        else if let str = try? container.decode(String.self, forKey: .baseShippingFee), let v = Int(str) { baseShippingFee = v }
        else if let str = try? container.decode(String.self, forKey: .base_shipping_fee), let v = Int(str) { baseShippingFee = v }
        else if let str = try? container.decode(String.self, forKey: .BASE_SHIPPING_FEE), let v = Int(str) { baseShippingFee = v }
        else { baseShippingFee = 0 }

        // freeShippingThreshold: Int or String
        if let val = try? container.decode(Int.self, forKey: .freeShippingThreshold) { freeShippingThreshold = val }
        else if let val = try? container.decode(Int.self, forKey: .free_shipping_threshold) { freeShippingThreshold = val }
        else if let val = try? container.decode(Int.self, forKey: .FREE_SHIPPING_THRESHOLD) { freeShippingThreshold = val }
        else if let str = try? container.decode(String.self, forKey: .freeShippingThreshold), let v = Int(str) { freeShippingThreshold = v }
        else if let str = try? container.decode(String.self, forKey: .free_shipping_threshold), let v = Int(str) { freeShippingThreshold = v }
        else if let str = try? container.decode(String.self, forKey: .FREE_SHIPPING_THRESHOLD), let v = Int(str) { freeShippingThreshold = v }
        else { freeShippingThreshold = 0 }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(branchId, forKey: .branchId)
        try container.encode(branchCode, forKey: .branchCode)
        try container.encode(branchName, forKey: .branchName)
        try container.encode(logoImageUrl, forKey: .logoImageUrl)
        try container.encode(branchStatus, forKey: .branchStatus)
        try container.encode(companyName, forKey: .companyName)
        try container.encode(tossClientKey, forKey: .tossClientKey)
        try container.encode(baseShippingFee, forKey: .baseShippingFee)
        try container.encode(freeShippingThreshold, forKey: .freeShippingThreshold)
    }
}
