import Foundation

struct BranchInfoVo: Codable {
    let branchId: Int64?
    let branchCode: String?
    let branchName: String?
    let logoImageUrl: String?
    let branchStatus: String?
    let companyName: String?
    
    enum CodingKeys: String, CodingKey {
        case branchId = "branch_id"
        case branchCode = "branch_code"
        case branchName = "branch_name"
        case logoImageUrl = "logo_image_url"
        case branchStatus = "branch_status"
        case companyName = "company_name"
    }
}
