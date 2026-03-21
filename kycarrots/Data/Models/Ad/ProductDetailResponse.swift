//
//  ProductDetailResponse.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct ProductDetailResponse: Decodable {
    let product: ProductVo
    let imageMetas: [ProductImageVo]
    let reviewNo: Int?
    let qnaNo: Int?
    
    enum CodingKeys: String, CodingKey {
        case product
        case imageMetas
        case reviewNo
        case qnaNo
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        product = try container.decode(ProductVo.self, forKey: .product)
        imageMetas = try container.decode([ProductImageVo].self, forKey: .imageMetas)
        
        // Flexible decoding for counts
        if let rNo = try container.decodeIfPresent(Int.self, forKey: .reviewNo) {
            reviewNo = rNo
        } else if let rString = try container.decodeIfPresent(String.self, forKey: .reviewNo) {
            reviewNo = Int(rString)
        } else {
            reviewNo = 0
        }
        
        if let qNo = try container.decodeIfPresent(Int.self, forKey: .qnaNo) {
            qnaNo = qNo
        } else if let qString = try container.decodeIfPresent(String.self, forKey: .qnaNo) {
            qnaNo = Int(qString)
        } else {
            qnaNo = 0
        }
    }
}
