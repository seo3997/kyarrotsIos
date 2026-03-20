import Foundation

struct BranchInfoVo: Codable {
    let branchId: Int64?
    let branchCode: String?
    let branchName: String?
    let logoImageUrl: String?
    let branchStatus: String?
    let companyName: String?
    
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
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        branchId = try container.decodeIfPresent(Int64.self, forKey: .branchId) ??
                   container.decodeIfPresent(Int64.self, forKey: .branch_id) ??
                   container.decodeIfPresent(Int64.self, forKey: .BRANCH_ID)
        
        branchCode = try container.decodeIfPresent(String.self, forKey: .branchCode) ??
                     container.decodeIfPresent(String.self, forKey: .branch_code) ??
                     container.decodeIfPresent(String.self, forKey: .BRANCH_CODE)
        
        branchName = try container.decodeIfPresent(String.self, forKey: .branchName) ??
                     container.decodeIfPresent(String.self, forKey: .branch_name) ??
                     container.decodeIfPresent(String.self, forKey: .BRANCH_NAME)
        
        logoImageUrl = try container.decodeIfPresent(String.self, forKey: .logoImageUrl) ??
                       container.decodeIfPresent(String.self, forKey: .logo_image_url) ??
                       container.decodeIfPresent(String.self, forKey: .LOGO_IMAGE_URL)
        
        branchStatus = try container.decodeIfPresent(String.self, forKey: .branchStatus) ??
                       container.decodeIfPresent(String.self, forKey: .branch_status) ??
                       container.decodeIfPresent(String.self, forKey: .BRANCH_STATUS)
        
        companyName = try container.decodeIfPresent(String.self, forKey: .companyName) ??
                      container.decodeIfPresent(String.self, forKey: .company_name) ??
                      container.decodeIfPresent(String.self, forKey: .COMPANY_NAME)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(branchId, forKey: .branchId)
        try container.encode(branchCode, forKey: .branchCode)
        try container.encode(branchName, forKey: .branchName)
        try container.encode(logoImageUrl, forKey: .logoImageUrl)
        try container.encode(branchStatus, forKey: .branchStatus)
        try container.encode(companyName, forKey: .companyName)
    }
}
