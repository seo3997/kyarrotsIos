//
//  CurrencyUtil.swift
//  kycarrots
//

import Foundation

struct CurrencyUtil {
    static func formatCurrency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedStr = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formattedStr)원"
    }
}
