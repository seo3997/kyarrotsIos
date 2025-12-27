import Foundation

enum PushType: String {
    case chat
    case product
}

struct PushDeepLink {
    let type: PushType
    let roomId: String?
    let buyerId: String?
    let sellerId: String?     // ✅ product push에서도 사용 가능
    let productId: String?
    let msg: String?

    static func from(userInfo: [AnyHashable: Any]) -> PushDeepLink? {
        guard let typeStr = (userInfo["type"] as? String)?.lowercased(),
              let type = PushType(rawValue: typeStr) else { return nil }

        return PushDeepLink(
            type: type,
            roomId: userInfo["roomId"] as? String,
            buyerId: userInfo["buyerId"] as? String,

            // ✅ product push에서 EXTRA_USER_ID 역할
            sellerId: (userInfo["sellerId"] as? String) ?? (userInfo["userId"] as? String),

            productId: userInfo["productId"] as? String,
            msg: userInfo["msg"] as? String
        )
    }
}
