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

    // MARK: - 생성자 (기본값 포함)
    init(
        token: String,
        adCode: Int,
        pageno: Int,
        categoryGroup: String? = "R010610",   // ★ Android 기본값 반영
        categoryMid: String? = nil,
        categoryScls: String? = nil,
        areaGroup: String? = "R010070",       // ★ Android 기본값 반영
        areaMid: String? = nil,
        areaScls: String? = nil,
        minPrice: Int? = nil,
        maxPrice: Int? = nil,
        saleStatus: String? = "1",            // ★ Android 기본값 반영
        memberCode: String? = ""              // ★ Android 기본값 반영
    ) {
        self.token = token
        self.adCode = adCode
        self.pageno = pageno
        self.categoryGroup = categoryGroup
        self.categoryMid = categoryMid
        self.categoryScls = categoryScls
        self.areaGroup = areaGroup
        self.areaMid = areaMid
        self.areaScls = areaScls
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.saleStatus = saleStatus
        self.memberCode = memberCode
    }
}
