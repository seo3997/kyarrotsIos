//
//  NotifType.swift
//  kycarrots
//
//  Created by soo on 12/26/25.
//


import Foundation

enum NotifType {
    static let CHAT = "CHAT"
    static let PRODUCT_REGISTERED = "PRODUCT_REGISTERED"
    static let PRODUCT_APPROVED = "PRODUCT_APPROVED"
    static let PRODUCT_REJECTED = "PRODUCT_REJECTED"
    static let PRODUCT = "PRODUCT"
    static let ORDER = "ORDER"
    static let SYS = "SYS"

    // ✅ "product" 계열 타입일 경우 deeplink 수동 생성 (Android 로직과 동기화)
    static func generateDeeplink(type: String, targetId: String?, deeplink: String?) -> String? {
        var result = deeplink
        let lowerType = type.lowercased()
        if (lowerType == "product" || lowerType.contains("product")) && (result == nil || result?.isEmpty == true) {
            let pid = targetId ?? ""
            result = "app://product/\(pid)"
        }
        return result
    }
}
