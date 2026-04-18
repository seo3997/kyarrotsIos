import UIKit
import UserNotifications
import KakaoSDKAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // ✅ AppDelegate에서 푸시 탭 시 Intro로 재라우팅할 때 사용
    var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // ✅ (중요) 앱이 terminated 상태였다가 "푸시 탭"으로 켜진 경우 deepLink 추출
        let deepLink = extractDeepLink(from: connectionOptions)

        // ✅ 항상 Intro부터 시작 (Android IntroActivity 역할)
        let coordinator = AppCoordinator(window: window)
        self.appCoordinator = coordinator
        coordinator.start(launchDeepLink: deepLink)
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // ✅ 앱이 포그라운드로 올라올 때마다 뱃지 카운트 동기화
        if let userId = UserDefaults.standard.string(forKey: "LogIn_ID") {
            NotificationBadgeHelper.refreshBadgeCount(userId: userId)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }

        if AuthApi.isKakaoTalkLoginUrl(url) {
            _ = AuthController.handleOpenUrl(url: url)
        }
    }
    /// ✅ terminated(콜드 스타트) 상태의 푸시 탭 딥링크 추출
    private func extractDeepLink(from options: UIScene.ConnectionOptions) -> PushDeepLink? {
        guard let response = options.notificationResponse else { return nil }
        let userInfo = response.notification.request.content.userInfo

        // PushType.swift 파서 그대로 사용
        return PushDeepLink.from(userInfo: userInfo)
    }

    // ⚠️ 이 메서드는 없어도 됨(UNUserNotificationCenterDelegate는 AppDelegate가 담당)
    // 남겨두면 "여기서 탭 처리하는 건가?" 혼동만 생김.
    /*
    func scene(
        _ scene: UIScene,
        didReceive response: UNNotificationResponse,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
    */
}
