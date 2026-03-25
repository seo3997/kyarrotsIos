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

    static func from(userInfo: [AnyHashable: Any]) -> PushDeepLink? {
        let typeStr = (userInfo["type"] as? String)?.lowercased() ?? ""
        let type = PushType(rawValue: typeStr) ?? .sys

        // targetId 직접 추출
        let targetId = userInfo["targetId"] as? String
        
        return PushDeepLink(
            type: type,
            targetId: targetId,
            msg: userInfo["msg"] as? String
        )
    }
}
