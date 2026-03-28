import UIKit
import UserNotifications
import CoreData

import FirebaseCore
import FirebaseMessaging

import KakaoSDKCommon
import KakaoSDKAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // ✅ Firebase 초기화
        FirebaseApp.configure()

        // ✅ FCM token 콜백
        Messaging.messaging().delegate = self

        // ✅ UNUserNotificationCenter delegate 지정 (필수)
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // ✅ 알림 권한 요청
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("🔔 Notification permission granted:", granted, "error:", String(describing: error))
            guard granted else { return }

            // ⚠️ 시뮬레이터에서는 의미 없고, 실기기에서만 사용됨
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
        
        // ✅ Kakao SDK init (Info.plist의 KakaoNativeAppKey 사용)
        if let key = Bundle.main.object(forInfoDictionaryKey: "KakaoNativeAppKey") as? String {
            KakaoSDK.initSDK(appKey: key)
        }
        
        return true
    }
    func application(
           _ app: UIApplication,
           open url: URL,
           options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        
        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }
        return false
        
    }
    // ✅ APNs 토큰을 받으면 FCM에게 연결해줘야 FCM->APNs 라우팅됨
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // (선택) 로그용 APNs 토큰
        let apnsHex = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📌 APNs token(hex):", apnsHex)

        // ✅ 핵심: FCM SDK에 APNs 토큰 연결
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ APNs register failed:", error)
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        print("✅ FCM token:", fcmToken)

        // ✅ util에게 전담
        PushTokenUtil.onNewToken(fcmToken)
    }
    
    // ✅ silent/background push (content-available:1) 수신
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📩 background fetch push:", userInfo)
        savePushToLocalDb(userInfo: userInfo)
        completionHandler(.newData)
    }
    

    // MARK: - Foreground 표시 + 저장
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        // 🔥 포그라운드 푸시 최초 진입 로그
        print("🔥userNotificationCenter  [PUSH] willPresent (foreground) userInfo:", userInfo)

        savePushToLocalDb(userInfo: userInfo)
        
        let pushEnabled = UserDefaults.standard.object(forKey: "push_enabled") as? Bool ?? true
        if pushEnabled {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        savePushToLocalDb(userInfo: userInfo) // 기존 유지

        // ✅ PushType.swift의 파서 사용
        let deepLink = PushDeepLink.from(userInfo: userInfo)

        DispatchQueue.main.async {
            self.routeViaIntro(deepLink: deepLink)
        }
        completionHandler()
    }

    private func routeViaIntro(deepLink: PushDeepLink?) {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let sceneDelegate = scene.delegate as? SceneDelegate
        else { return }

        // ✅ Android: PendingIntent -> IntroActivity 와 동일
        sceneDelegate.appCoordinator?.start(launchDeepLink: deepLink)
    }

    // MARK: - 알림 리스트 화면 열기
    private func openNotificationList() {
        AppCoordinator.shared?.showNotificationList()
    }

    // MARK: - UISceneSession Lifecycle
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

// 기존 DB 저장 로직 그대로 유지
extension AppDelegate {

    func savePushToLocalDb(userInfo: [AnyHashable: Any]) {
        // ✅ push id 추출 (없으면 gcm.message_id 시도, 그래도 없으면 새로 생성하여 저장 누락 방지)
        let idVal = userInfo["id"] ?? userInfo["gcm.message_id"] ?? userInfo["google.message_id"]
        let idStr = idVal as? String ?? ""
        
        let pushId = UUID(uuidString: idStr) ?? UUID()

        let ctx = PersistenceController.shared.container.viewContext
        ctx.perform {
            let req = NSFetchRequest<CDPushNotification>(entityName: "CDPushNotification")
            req.predicate = NSPredicate(format: "id == %@", pushId as CVarArg)
            req.fetchLimit = 1

            do {
                if try ctx.fetch(req).first != nil {
                    print("⏭️ 이미 저장된 push:", pushId)
                    return
                }
            } catch {
                print("❌ 중복 체크 실패:", error)
                return
            }

            let aps = userInfo["aps"] as? [String: Any]
            let alert = aps?["alert"] as? [String: Any]
            let titleFromAps = alert?["title"] as? String
            let bodyFromAps  = alert?["body"] as? String

            let title = (userInfo["title"] as? String) ?? titleFromAps ?? ""
            let body  = (userInfo["body"] as? String) ?? bodyFromAps ?? (userInfo["msg"] as? String)

            let type = (userInfo["type"] as? String) ?? ""
            let targetId = userInfo["targetId"] as? String
            var deeplink = userInfo["deeplink"] as? String
            
            // ✅ "product" 타입일 경우 deeplink 수동 생성 (Android 로직과 동기화)
            if type.lowercased() == "product" && (deeplink == nil || deeplink?.isEmpty == true) {
                let pid = targetId ?? ""
                deeplink = "app://product/\(pid)"
            }

            let userId = UserDefaults.standard.string(forKey: "LogIn_ID") ?? ""

            let row = CDPushNotification(context: ctx)
            row.id = pushId
            row.userId = userId
            row.type = type
            row.title = title
            row.body = body
            row.targetId = targetId
            row.deeplink = deeplink
            row.isRead = false
            row.createdAt = Date()

            do {
                try ctx.save()
                print("✅ push 저장 완료:", pushId)
                NotificationBadgeHelper.refreshBadgeCount(userId: userId)
                NotificationCenter.default.post(name: .didReceiveNewPush, object: nil)
            } catch {
                print("❌ push 저장 실패:", error)
            }
        }
    }
}
