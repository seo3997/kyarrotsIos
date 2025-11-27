//
//  PurchaseHistoryRequest.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct PurchaseHistoryRequest: Encodable {
    let productId: Int64
    let buyerNo: Int64
    let roomId: String?
    let sellerNo: Int64
}
