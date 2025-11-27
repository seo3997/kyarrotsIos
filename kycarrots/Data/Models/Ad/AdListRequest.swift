//
//  AdListRequest.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct AdListRequest: Encodable {
    let token: String
    let adCode: Int
    let pageno: Int
    let categoryGroup: String?
    let categoryMid: String?
    let categoryScls: String?
    let areaGroup: String?
    let areaMid: String?
    let areaScls: String?
    let minPrice: Int?
    let maxPrice: Int?
    var saleStatus: String?
    var memberCode: String?
}
