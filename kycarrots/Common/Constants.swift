//
//  Constants.swift
//  kycarrots
//
//  Created by soo on 11/29/25.
//


//
//  Constants.swift
//  kycarrots
//

import Foundation

struct Constants {

    // MARK: - Server Type (LOCAL / DEV / PROD)
    enum ServerType {
        case LOCAL
        case DEV
        case PROD
    }

    /// 현재 서버 설정 (Android Constants.kt의 currentServer 대응)
    private static let currentServer: ServerType = .DEV

    // MARK: - Base URL (Android Constants.kt BASE_URL 대응)
    static var BASE_URL: String {
        switch currentServer {
        case .LOCAL:
            return "http://10.69.122.25:9000/"
        case .DEV:
            return "http://52.231.229.156:9000/"
        case .PROD:
            return "http://52.231.229.156:9000/"
        }
    }

    // MARK: - WebSocket URL
    static var WS_URL: String {
        switch currentServer {
        case .LOCAL:
            return "ws://10.69.122.25:9000/chat-ws?userId="
        case .DEV:
            return "ws://52.231.229.156:9000/chat-ws?userId="
        case .PROD:
            return "ws://52.231.229.156:9000/chat-ws?userId="
        }
    }
    
    static func wsURL(userId: String) -> URL {
          URL(string: WS_URL + userId)!
    }
    
    // MARK: - SYSTEM TYPE
    /// Android: const val SYSTEM_TYPE = 2
    static let SYSTEM_TYPE = 2   // 1: 직거래, 2: 중간센터

    // MARK: - ROLE CODE
    static let ROLE_PUB  = "ROLE_PUB"
    static let ROLE_SELL = "ROLE_SELL"
    static let ROLE_PROJ = "ROLE_PROJ"
}
