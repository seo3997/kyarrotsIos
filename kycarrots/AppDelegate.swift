import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // --- 이 부분을 추가합니다 ---
              UNUserNotificationCenter.current().delegate = self
              UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                  print("Permission granted: \(granted)")
                  guard granted else { return }
                  
                  // APNS에 디바이스 토큰 등록 요청 (실제 기기 테스트용)
                  DispatchQueue.main.async {
                      application.registerForRemoteNotifications()
                  }
              }
              // ---------
        return true
    }
    // 포그라운드에서도 알림 배너를 보게 하려면 이 메서드도 추가
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                  willPresent notification: UNNotification,
                                  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
          completionHandler([.banner, .sound, .badge])
    }
    
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
