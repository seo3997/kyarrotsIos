import UIKit
import UserNotifications
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // ✅ UNUserNotificationCenter delegate 지정 (필수)
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // ✅ 알림 권한 요청
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("🔔 Notification permission granted:", granted)

            guard granted else { return }

            // ⚠️ 시뮬레이터에서는 의미 없고, 실기기에서만 사용됨
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }

        return true
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📩 background fetch push:", userInfo)

        // ✅ silent/background push로 들어온 데이터 저장
        //savePushToLocalDb(userInfo: userInfo)

        completionHandler(.newData)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        savePushToLocalDb(userInfo: userInfo) // ✅ 수신 시 저장
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        savePushToLocalDb(userInfo: userInfo) // ✅ 탭 시에도 호출해도 OK(중복방지됨)

        DispatchQueue.main.async {
            self.openNotificationList()
        }
        completionHandler()
    }

    // MARK: - 알림 리스트 화면 열기
    private func openNotificationList() {
        let vc = NotificationListViewController()

        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first,
            let root = window.rootViewController
        else { return }

        if let nav = root as? UINavigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            window.rootViewController = nav
            window.makeKeyAndVisible()
        }
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

extension AppDelegate {

    func savePushToLocalDb(userInfo: [AnyHashable: Any]) {
        // ✅ 서버에서 내려준 id가 없으면 저장 불가(중복 방지 불가)
        guard let idStr = userInfo["id"] as? String,
              let pushId = UUID(uuidString: idStr) else {
            print("❌ push id 없음 -> 저장 스킵. userInfo=", userInfo)
            return
        }

        let ctx = PersistenceController.shared.container.viewContext
        ctx.perform {
            // 1) 중복 체크
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
                // 중복 체크 실패면 안전하게 저장 스킵하거나 계속 진행 중 선택.
                // 여기선 스킵하지 않고 계속 저장 진행하지 않도록 return 권장:
                return
            }

            // 2) 값 파싱(aps.alert + data 둘 다 대응)
            let aps = userInfo["aps"] as? [String: Any]
            let alert = aps?["alert"] as? [String: Any]
            let titleFromAps = alert?["title"] as? String
            let bodyFromAps  = alert?["body"] as? String

            let title = (userInfo["title"] as? String) ?? titleFromAps ?? ""
            let body  = (userInfo["body"] as? String) ?? bodyFromAps ?? (userInfo["msg"] as? String)

            let type = (userInfo["type"] as? String) ?? ""
            let roomId = userInfo["roomId"] as? String
            let sellerId = userInfo["sellerId"] as? String
            let deeplink = userInfo["deeplink"] as? String

            let productIdStr = userInfo["productId"] as? String
            let productIdVal: Int64 = Int64(productIdStr ?? "") ?? 0

            let userId = UserDefaults.standard.string(forKey: "LogIn_ID") ?? ""

            // 3) 저장
            let row = CDPushNotification(context: ctx)
            row.id = pushId                 // ✅ 서버 id 사용
            row.userId = userId
            row.type = type
            row.title = title
            row.body = body
            row.productId = productIdVal
            row.sellerId = sellerId
            row.roomId = roomId
            row.deeplink = deeplink
            row.isRead = false
            row.createdAt = Date()          // ✅ 현재일시

            do {
                try ctx.save()
                print("✅ push 저장 완료:", pushId)
            } catch {
                print("❌ push 저장 실패:", error)
            }
        }
    }
}
