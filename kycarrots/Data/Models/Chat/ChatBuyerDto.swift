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
    let sellerId: String
    let buyerId: String
    let buyerNo: Int64
    let buyerNm: String
    let sellerNo: Int64
    let sellerNm: String

    enum CodingKeys: String, CodingKey {
        case roomId     = "room_id"
        case productId  = "product_id"
        case sellerId   = "seller_id"
        case buyerId    = "buyer_id"
        case buyerNo    = "buyer_no"
        case buyerNm    = "buyer_nm"
        case sellerNo   = "seller_no"
        case sellerNm   = "seller_nm"
    }
}
