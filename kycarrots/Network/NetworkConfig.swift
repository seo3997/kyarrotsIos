//
//  NetworkConfig.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

enum NetworkConfig {
    // 안드로이드 BASE_URL 과 동일하게 맞추기
    static let baseURL = URL(string: "https://www.kycarrots.com/")!

    // 로그인 후 받은 JWT 등
    static var accessToken: String?
}
