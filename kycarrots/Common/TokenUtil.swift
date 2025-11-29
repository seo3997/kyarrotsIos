//
//  TokenUtil.swift
//  kycarrots
//
//  Created by soo on 11/29/25.
//


import Foundation

struct TokenUtil {
    private static let PREF_NAME = "TokenInfo"   // 이름만 맞춰둔 상태
    private static let TOKEN_KEY = "token"
    private static let defaults = UserDefaults.standard

    static func getToken() -> String {
        return defaults.string(forKey: TOKEN_KEY) ?? ""
    }

    static func saveToken(_ token: String) {
        defaults.set(token, forKey: TOKEN_KEY)
    }

    static func clearToken() {
        defaults.removeObject(forKey: TOKEN_KEY)
    }
}
