import Foundation
import FirebaseMessaging

// ✅ 서버에 보낼 VO가 이미 있다고 가정
// struct PushTokenVo: Encodable { ... }

struct PushTokenUtil {

    // 마지막으로 "서버 저장 성공한" FCM 토큰
    private static let KEY = "push_fcm_token"
    private static let defaults = UserDefaults.standard

    static func get() -> String { defaults.string(forKey: KEY) ?? "" }
    static func save(_ token: String) { defaults.set(token, forKey: KEY) }
    static func clear() { defaults.removeObject(forKey: KEY) }

    /// ✅ 실제 서버 업로드 + 성공 시 로컬 저장
    static func uploadPushTokenToServer(_ fcmToken: String) async -> Bool {
        let userId = UserDefaults.standard.string(forKey: "LogIn_ID") ?? ""
        let userNo = UserDefaults.standard.string(forKey: "LogIn_NO") ?? ""

        guard !userId.isEmpty else {
            print("⚠️ 로그인 전 상태 → 푸시 토큰 서버 저장 스킵")
            return false
        }

        // ✅ 중복이면 서버 호출 스킵
        if get() == fcmToken {
            print("⏭️ same token → upload skip")
            return true
        }

        let req = PushTokenVo(
            userNo: userNo,
            userId: userId,
            pushToken: fcmToken,
            deviceType: "IOS"
        )

        let ok = await AppServiceProvider.shared.savePushToken(req)
        print(ok ? "✅ iOS PushToken 서버 저장 성공" : "❌ iOS PushToken 서버 저장 실패")

        if ok { save(fcmToken) }   // ✅ 성공 시만 로컬 저장
        return ok
    }

    /// ✅ Android의 ensureTokenRegistered와 동일:
    /// 로컬에 토큰이 없을 때만 "현재 FCM 토큰"을 조회해서 서버 업로드 시도
    static func ensureTokenRegistered() {
        if !get().isEmpty {
            print("✅ last token exists → skip getToken")
            return
        }

        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ getToken failed:", error)
                return
            }
            guard let token, !token.isEmpty else { return }

            Task {
                _ = await uploadPushTokenToServer(token)
            }
        }
    }

    /// ✅ 토큰 변경 이벤트(didReceiveRegistrationToken)에서 호출용
    static func onNewToken(_ token: String) {
        Task {
            _ = await uploadPushTokenToServer(token)
        }
    }
}
