import UIKit
import SideMenu
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // ✅ 앱 코디네이터(Intro -> Login/Home 라우팅)
    var appCoordinator: AppCoordinator?   // 🔥 private 제거 + 이름 통일

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // ✅ 푸시로 앱이 열렸으면 딥링크 추출
        let deepLink = extractDeepLink(from: connectionOptions)

        // ✅ Intro부터 시작
        let coordinator = AppCoordinator(window: window)
        self.appCoordinator = coordinator   // 🔥 여기 저장
        coordinator.start(launchDeepLink: deepLink)
    }

    // terminated 상태 푸시 딥링크
    private func extractDeepLink(from options: UIScene.ConnectionOptions) -> PushDeepLink? {
        if let response = options.notificationResponse {
            return PushDeepLink.from(userInfo: response.notification.request.content.userInfo)
        }
        return nil
    }

    func scene(_ scene: UIScene,
               didReceive response: UNNotificationResponse,
               completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
