//
//  ReviewVo.swift
//  kycarrots
//
//  Created by soohyun on 03/21/26.
//

import Foundation

struct ReviewVo: Codable, Identifiable {
    var id: String { reviewId ?? UUID().uuidString }
    let reviewId: String?
    let productId: String?
    let userNo: String?
    let userNm: String?
    let rating: Int
    let contents: String?
    let registDt: String?
    let displayYn: String?
    let atchDocId: String?
    let fileRltvPath: String?
    let filePaths: String?

    init(
        reviewId: String? = nil,
        productId: String? = nil,
        userNo: String? = nil,
        userNm: String? = nil,
        rating: Int = 0,
        contents: String? = nil,
        registDt: String? = nil,
        displayYn: String? = nil,
        atchDocId: String? = nil,
        fileRltvPath: String? = nil,
        filePaths: String? = nil
    ) {
        self.reviewId = reviewId
        self.productId = productId
        self.userNo = userNo
        self.userNm = userNm
        self.rating = rating
        self.contents = contents
        self.registDt = registDt
        self.displayYn = displayYn
        self.atchDocId = atchDocId
        self.fileRltvPath = fileRltvPath
        self.filePaths = filePaths
    }

    enum CodingKeys: String, CodingKey {
        case reviewId = "REVIEW_ID"
        case productId = "PRODUCT_ID"
        case userNo = "USER_NO"
        case userNm = "USER_NM"
        case rating = "RATING"
        case contents = "CONTENTS"
        case registDt = "REGIST_DT"
        case displayYn = "DISPLAY_YN"
        case atchDocId = "ATCH_DOC_ID"
        case fileRltvPath = "FILE_RLTV_PATH"
        case filePaths = "FILE_PATHS"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle REVIEW_ID as String or Int64
        if let rId = try? container.decodeIfPresent(String.self, forKey: .reviewId) {
            reviewId = rId
        } else if let rIdInt = try? container.decodeIfPresent(Int64.self, forKey: .reviewId) {
            reviewId = String(rIdInt)
        } else {
            reviewId = nil
        }
            
        // Handle PRODUCT_ID as String or Int64
        if let pIdInt = try? container.decodeIfPresent(Int64.self, forKey: .productId) {
            productId = String(pIdInt)
        } else if let pId = try? container.decodeIfPresent(String.self, forKey: .productId) {
            productId = pId
        } else {
            productId = nil
        }
            
        // Handle USER_NO as String or Int64
        if let uNo = try? container.decodeIfPresent(String.self, forKey: .userNo) {
            userNo = uNo
        } else if let uNoInt = try? container.decodeIfPresent(Int64.self, forKey: .userNo) {
            userNo = String(uNoInt)
        } else {
            userNo = nil
        }
            
        userNm = try container.decodeIfPresent(String.self, forKey: .userNm)
        
        // Flexible decoding for RATING (Int)
        if let rInt = try? container.decodeIfPresent(Int.self, forKey: .rating) {
            rating = rInt
        } else if let rString = try? container.decodeIfPresent(String.self, forKey: .rating) {
            rating = Int(rString) ?? 0
        } else if let rInt64 = try? container.decodeIfPresent(Int64.self, forKey: .rating) {
            rating = Int(rInt64)
        } else {
            rating = 0
        }
        
        contents = try container.decodeIfPresent(String.self, forKey: .contents)
        registDt = try container.decodeIfPresent(String.self, forKey: .registDt)
        displayYn = try container.decodeIfPresent(String.self, forKey: .displayYn)
        atchDocId = try container.decodeIfPresent(String.self, forKey: .atchDocId)
        fileRltvPath = try container.decodeIfPresent(String.self, forKey: .fileRltvPath)
        filePaths = try container.decodeIfPresent(String.self, forKey: .filePaths)
    }
}
