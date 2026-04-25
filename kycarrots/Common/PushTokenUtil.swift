import Foundation
import FirebaseMessaging

// ✅ 서버에 보낼 VO가 이미 있다고 가정
// struct PushTokenVo: Encodable { ... }

struct PushTokenUtil {

    // 마지막으로 "서버 저장 성공한" 정보들
    private static let KEY_TOKEN = "push_fcm_token"
    private static let KEY_USER_ID = "push_last_user_id"
    private static let defaults = UserDefaults.standard

    static func get() -> String { defaults.string(forKey: KEY_TOKEN) ?? "" }
    static func getLastUserId() -> String { defaults.string(forKey: KEY_USER_ID) ?? "" }
    
    static func save(_ token: String, _ userId: String) {
        defaults.set(token, forKey: KEY_TOKEN)
        defaults.set(userId, forKey: KEY_USER_ID)
    }
    
    static func clear() {
        defaults.removeObject(forKey: KEY_TOKEN)
        defaults.removeObject(forKey: KEY_USER_ID)
    }

    /// ✅ 실제 서버 업로드 + 성공 시 로컬 저장
    static func uploadPushTokenToServer(_ fcmToken: String) async -> Bool {
        let userId = LoginInfoUtil.getUserId()
        let userNo = LoginInfoUtil.getUserNo()
        let memberCode = LoginInfoUtil.getMemberCode()

        guard !userId.isEmpty else {
            print("⚠️ 로그인 전 상태 → 푸시 토큰 서버 저장 스킵")
            return false
        }

        // ✅ 토큰과 유저 아이디가 모두 일치할 때만 스킵
        if get() == fcmToken && getLastUserId() == userId {
            print("⏭️ same token & user → upload skip")
            // 업로드 스킵하더라도 토픽 구독은 보장
            subscribeToMemberTopic(memberCode)
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

        if ok { 
            save(fcmToken, userId)
            subscribeToMemberTopic(memberCode)
        }
        return ok
    }

    /// ✅ Android의 subscribeToTopic과 동일: memberCode 기반 토픽 구독
    static func subscribeToMemberTopic(_ memberCode: String) {
        guard !memberCode.isEmpty else { return }
        
        // 1. 권한별 토픽 구독 (ROLE_PUB, ROLE_SELL 등)
        Messaging.messaging().subscribe(toTopic: memberCode) { error in
            if let error = error {
                print("❌ FCM \(memberCode) 토픽 구독 실패:", error.localizedDescription)
            } else {
                print("✅ FCM \(memberCode) 토픽 구독 성공")
            }
        }

        // 2. 지점별 토픽 구독 (지점 권한 ROLE_PROJ 인 경우)
        let branchId = LoginInfoUtil.getBranchId()
        if memberCode == "ROLE_PROJ" {
            let branchTopic = "BRANCH_\(branchId)_ROLE_PROJ"
            Messaging.messaging().subscribe(toTopic: branchTopic) { error in
                if let error = error {
                    print("❌ FCM \(branchTopic) 지점 토픽 구독 실패:", error.localizedDescription)
                } else {
                    print("✅ FCM \(branchTopic) 지점 토픽 구독 성공")
                }
            }
        }
    }

    /// ✅ Android의 ensureTokenRegistered와 동일:
    /// 로컬에 토큰이 없거나, 유저가 바뀌었을 때 "현재 FCM 토큰"을 조회해서 서버 업로드 시도
    static func ensureTokenRegistered() {
        let userId = LoginInfoUtil.getUserId()
        let memberCode = LoginInfoUtil.getMemberCode()

        if !get().isEmpty && getLastUserId() == userId && !userId.isEmpty {
            print("✅ last token & user match → skip getToken")
            subscribeToMemberTopic(memberCode)
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
