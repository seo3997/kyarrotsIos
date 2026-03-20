//
//  ChatBuyerDto.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct ChatBuyerDto: Decodable {
    let roomId: String
    let productId: Int64
    let branchId: String
    let buyerId: String
    let buyerNo: Int64
    let buyerNm: String
    let sellerNo: Int64
    let sellerNm: String

    enum CodingKeys: String, CodingKey {
        case roomId
        case productId
        case branchId
        case buyerId
        case buyerNo
        case buyerNm
        case sellerNo
        case sellerNm
    }
}
