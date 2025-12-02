//
//  ProductVo.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct ProductVo: Codable {
    let productId: String?
    let userNo: String?
    let title: String
    let description: String?
    let price: String?
    let categoryGroup: String?
    let categoryMid: String?
    let categoryScls: String?
    let saleStatus: String?
    let areaGroup: String?
    let areaMid: String?
    let areaScls: String?
    let quantity: String?
    let unitGroup: String?
    let unitCode: String?
    let desiredShippingDate: String?
    let registerNo: String?
    let registDt: String?
    let updusrNo: String?
    let updtDt: String?
    let imageUrl: String?

    let categoryMidNm: String?
    let categorySclsNm: String?
    let areaMidNm: String?
    let areaSclsNm: String?
    let unitCodeNm: String?
    let saleStatusNm: String?
    let userId: String?
    let wholesalerNo: String?
    let wholesalerId: String?
    let fav: String?
    let systemType: String?
    let rejectReason: String?
}
