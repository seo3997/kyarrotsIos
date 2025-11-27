//
//  ProductItem.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct ProductItem: Encodable {
    let productId: String
    let saleStatus: String
    let updusrNo: Int
    let rejectReason: String?
    let systemType: String
}
