//
//  NetworkConfig.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

enum NetworkConfig {
    // 안드로이드 BASE_URL 과 동일하게 맞추기
    static var baseURL: URL {
        URL(string: Constants.BASE_URL)!
    }
    
    static var websocketURL: String {
        return Constants.WS_URL
    }
    
    // 로그인 후 받은 JWT 등
    static var accessToken: String?
}
