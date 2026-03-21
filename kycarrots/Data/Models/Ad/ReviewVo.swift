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
        fileRltvPath: String? = nil
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
    }

    enum CodingKeys: String, CodingKey {
        case reviewId
        case productId
        case userNo
        case userNm
        case rating
        case contents
        case registDt
        case displayYn
        case atchDocId
        case fileRltvPath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        reviewId = (try? container.decodeIfPresent(String.self, forKey: .reviewId))
            ?? (try? container.decodeIfPresent(Int64.self, forKey: .reviewId)).map { String($0) }
            
        productId = (try? container.decodeIfPresent(Int64.self, forKey: .productId)).map { String($0) }
            ?? (try? container.decodeIfPresent(String.self, forKey: .productId))
            
        userNo = (try? container.decodeIfPresent(String.self, forKey: .userNo))
            ?? (try? container.decodeIfPresent(Int64.self, forKey: .userNo)).map { String($0) }
            
        userNm = try container.decodeIfPresent(String.self, forKey: .userNm)
        
        // Flexible decoding for rating (Int)
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
    }
}
