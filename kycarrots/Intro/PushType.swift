import Foundation

enum PushType: String {
    case chat
    case product
    case order
    case sys
}

struct PushDeepLink {
    let type: PushType
    let targetId: String?
    let msg: String?
    let originalType: String // ✅ 추가

    static func from(userInfo: [AnyHashable: Any]) -> PushDeepLink? {
        let typeStr = (userInfo["type"] as? String)?.lowercased() ?? ""
        var type = PushType(rawValue: typeStr) ?? .sys

        // ✅ 상품 관련 타입 확장 매핑 (Android와 동기화)
        if typeStr.contains("product") || typeStr.contains("qna") || typeStr.contains("inquiry") || typeStr.contains("review") {
            type = .product
        }

        // targetId 직접 추출
        let targetId = userInfo["targetId"] as? String
        
        return PushDeepLink(
            type: type,
            targetId: targetId,
            msg: userInfo["msg"] as? String,
            originalType: typeStr // ✅ 원본 타입 보존
        )
    }
}
