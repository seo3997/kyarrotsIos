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
    private static let currentServer: ServerType = .PROD

    // MARK: - Base URL (Android Constants.kt BASE_URL 대응)
    static var BASE_URL: String {
        switch currentServer {
        case .LOCAL:
            return "http://10.133.36.8:9000/"
        case .DEV:
            return "http://www.kycarrots.com:9000/"
        case .PROD:
            return "http://www.asagong.com/"
        }
    }

    // MARK: - WebSocket URL
    static var WS_URL: String {
        switch currentServer {
        case .LOCAL:
            return "ws://10.133.36.8:9000/chat-ws?userId="
        case .DEV:
            return "ws://www.kycarrots.com:9000/chat-ws?userId="
        case .PROD:
            return "ws://www.asagong.com/chat-ws?userId="
        }
    }
    
    static func wsURL(userId: String) -> URL {
          URL(string: WS_URL + userId)!
    }
    
    // MARK: - CENTER BRANCH ID
    static let CENTER_BRANCH_ID = "2"   // 본사 지점 ID

    // MARK: - ROLE CODE
    static let ROLE_PUB  = "ROLE_PUB"
    static let ROLE_SELL = "ROLE_SELL"
    static let ROLE_PROJ = "ROLE_PROJ"
    static let ROLE_ADMIN = "ROLE_ADMIN"
    static let APP_TEST_YN = "N"   //N 일때 패스워드 안나옴

}

extension Optional where Wrapped == Any {
    func asString() -> String {
        if let val = self {
            if val is NSNull { return "" }
            let str = String(describing: val)
            if str == "<null>" || str == "null" { return "" }
            return str
        }
        return ""
    }
}
