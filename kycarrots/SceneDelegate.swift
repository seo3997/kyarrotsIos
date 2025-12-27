import UIKit
import SideMenu
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // ✅ SideMenu는 로그인 이후에만 세팅
    private var leftMenuNav: SideMenuNavigationController?

    // ✅ 앱 코디네이터(Intro -> Login/Home 라우팅)
    private var coordinator: AppCoordinator?

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
        self.coordinator = coordinator
        coordinator.start(launchDeepLink: deepLink)
    }

    // ✅ terminated 상태에서 푸시 클릭으로 열렸을 때 딥링크 파싱
    private func extractDeepLink(from options: UIScene.ConnectionOptions) -> PushDeepLink? {
        if let response = options.notificationResponse {
            return PushDeepLink.from(userInfo: response.notification.request.content.userInfo)
        }
        return nil
    }

    // ✅ (선택) 앱 실행 중(또는 백그라운드) 푸시 클릭으로 들어오면 여기로 들어옴
    func scene(_ scene: UIScene,
               didReceive response: UNNotificationResponse,
               completionHandler: @escaping () -> Void) {
        // 여기서도 딥링크를 파싱해서, 현재 화면이 로그인/홈 상태인지에 따라 라우팅 가능
        // 지금은 최소 구현으로 completion만 호출
        completionHandler()
    }
}
