//
//  PushRegIdUtil.swift
//  kycarrots
//
//  Created by soo on 12/27/25.
//


import Foundation

struct PushRegIdUtil {
    private static let KEY = "apns.regId"
    private static let defaults = UserDefaults.standard

    static func getRegId() -> String {
        defaults.string(forKey: KEY) ?? ""
    }

    static func saveRegId(_ value: String) {
        defaults.set(value, forKey: KEY)
    }

    static func clear() {
        defaults.removeObject(forKey: KEY)
    }
}
