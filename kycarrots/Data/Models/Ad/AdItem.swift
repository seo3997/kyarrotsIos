//
//  AdItem.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct AdItem: Codable, Identifiable {
    var id: String { productId ?? "" }
    
    let productId: String?
    let title: String?
    let description: String?
    let price: String?
    let imageUrl: String?
    let userId: String?
    
    // 주문 관련 필드 추가 (안드로이드 AdItem.kt 기준)
    let orderNo: String?
    let orderId: String?
    let paymentStatus: String?
    let orderStatusNm: String?
    let deliveredAt: String?
    let saleStatusNm: String?
    let deliveryCompanyNm: String?
    let trackingNo: String?
    let orderedAt: String?

    enum CodingKeys: String, CodingKey {
        case productId, title, description, price, imageUrl, userId
        case orderNo, orderId, paymentStatus, orderStatusNm
        case deliveredAt, saleStatusNm, deliveryCompanyNm, trackingNo, orderedAt
        
        // 대문자/언더바 대응 (Android alternate 매핑 반영)
        case PRODUCT_ID, TITLE, DESCRIPTION, PRICE, IMAGE_URL, USER_NO
        case ORDER_NO, ORDER_ID, PAYMENT_STATUS, ORDER_STATUS, ORDER_STATUS_NM
        case DELIVERED_AT, SALE_STATUS_NM, DELIVERY_COMPANY_NM, TRACKING_NO, ORDERED_AT
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productId = try container.decodeIfPresent(String.self, forKey: .productId) ?? container.decodeIfPresent(String.self, forKey: .PRODUCT_ID)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? container.decodeIfPresent(String.self, forKey: .TITLE)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? container.decodeIfPresent(String.self, forKey: .DESCRIPTION)
        price = try container.decodeIfPresent(String.self, forKey: .price) ?? container.decodeIfPresent(String.self, forKey: .PRICE)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl) ?? container.decodeIfPresent(String.self, forKey: .IMAGE_URL)
        userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? container.decodeIfPresent(String.self, forKey: .USER_NO)
        
        orderNo = try container.decodeIfPresent(String.self, forKey: .orderNo) ?? container.decodeIfPresent(String.self, forKey: .ORDER_NO)
        orderId = try container.decodeIfPresent(String.self, forKey: .orderId) ?? container.decodeIfPresent(String.self, forKey: .ORDER_ID)
        paymentStatus = try container.decodeIfPresent(String.self, forKey: .paymentStatus) ?? container.decodeIfPresent(String.self, forKey: .PAYMENT_STATUS) ?? container.decodeIfPresent(String.self, forKey: .ORDER_STATUS)
        orderStatusNm = try container.decodeIfPresent(String.self, forKey: .orderStatusNm) ?? container.decodeIfPresent(String.self, forKey: .ORDER_STATUS_NM)
        deliveredAt = try container.decodeIfPresent(String.self, forKey: .deliveredAt) ?? container.decodeIfPresent(String.self, forKey: .DELIVERED_AT)
        saleStatusNm = try container.decodeIfPresent(String.self, forKey: .saleStatusNm) ?? container.decodeIfPresent(String.self, forKey: .SALE_STATUS_NM)
        deliveryCompanyNm = try container.decodeIfPresent(String.self, forKey: .deliveryCompanyNm) ?? container.decodeIfPresent(String.self, forKey: .DELIVERY_COMPANY_NM)
        trackingNo = try container.decodeIfPresent(String.self, forKey: .trackingNo) ?? container.decodeIfPresent(String.self, forKey: .TRACKING_NO)
        orderedAt = try container.decodeIfPresent(String.self, forKey: .orderedAt) ?? container.decodeIfPresent(String.self, forKey: .ORDERED_AT)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(productId, forKey: .productId)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(userId, forKey: .userId)
        
        try container.encodeIfPresent(orderNo, forKey: .orderNo)
        try container.encodeIfPresent(orderId, forKey: .orderId)
        try container.encodeIfPresent(paymentStatus, forKey: .paymentStatus)
        try container.encodeIfPresent(orderStatusNm, forKey: .orderStatusNm)
        try container.encodeIfPresent(deliveredAt, forKey: .deliveredAt)
        try container.encodeIfPresent(saleStatusNm, forKey: .saleStatusNm)
        try container.encodeIfPresent(deliveryCompanyNm, forKey: .deliveryCompanyNm)
        try container.encodeIfPresent(trackingNo, forKey: .trackingNo)
        try container.encodeIfPresent(orderedAt, forKey: .orderedAt)
    }
}
