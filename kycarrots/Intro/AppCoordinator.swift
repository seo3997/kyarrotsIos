import UIKit
import SideMenu

final class AppCoordinator {
    private let window: UIWindow
    private let nav = UINavigationController()

    // ✅ 중요: strong reference로 들고 있어야 메뉴가 해제되지 않음
    private var leftMenuNav: SideMenuNavigationController?

    init(window: UIWindow) {
        self.window = window
        nav.setNavigationBarHidden(false, animated: false)
        window.rootViewController = nav
        window.makeKeyAndVisible()

        // ✅ SideMenu는 앱 시작 시 1번만 세팅
        setupSideMenu()
    }

    // ✅ SideMenu 설정
    private func setupSideMenu() {
        let menuVC = MenuListViewController()
        let menuNav = SideMenuNavigationController(rootViewController: menuVC)
        menuNav.leftSide = true
        menuNav.setNavigationBarHidden(true, animated: false)
        menuNav.presentationStyle = .menuSlideIn
        menuNav.menuWidth = min(300, UIScreen.main.bounds.width * 0.8)
        menuNav.statusBarEndAlpha = 0

        // ✅ retain
        self.leftMenuNav = menuNav

        // ✅ register
        SideMenuManager.default.leftMenuNavigationController = menuNav

        // ✅ gestures (선택이지만 있으면 편함)
        SideMenuManager.default.addPanGestureToPresent(toView: nav.view)
        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: nav.view, forMenu: .left)
    }

    func start(launchDeepLink: PushDeepLink?) {
        let intro = IntroViewController(
            service: AppServiceProvider.shared,
            coordinator: self,
            launchDeepLink: launchDeepLink
        )
        nav.setViewControllers([intro], animated: false)
    }

    func showLogin(pendingDeepLink: PushDeepLink?) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let vc = storyboard.instantiateViewController(
            withIdentifier: "LoginVC"
        ) as? LoginViewController else {
            assertionFailure("LoginVC not found in storyboard")
            return
        }

        vc.pendingDeepLink = pendingDeepLink
        nav.setViewControllers([vc], animated: true)
    }

    func showHome(memberCode: String, deepLink: PushDeepLink?) {
        // ✅ 1) 딥링크 우선
        if let deepLink {
            switch deepLink.type {
            case .chat:
                if let chat = makeChatVC(from: deepLink) {
                    nav.setViewControllers([chat], animated: true)
                    return
                }
            case .product:
                if let detail = makeProductDetailVC(from: deepLink) {
                    nav.setViewControllers([detail], animated: true)
                    return
                }
            }
        }

        // ✅ 2) 기본 랜딩
        if memberCode == "ROLE_SELL" || memberCode == "ROLE_PROJ" {
            nav.setViewControllers([makeDashboardVC()], animated: true)
        } else {
            nav.setViewControllers([makeMainTabBarVC()], animated: true)
        }
    }
}

// MARK: - Storyboard Factory
private extension AppCoordinator {

    var storyboard: UIStoryboard {
        UIStoryboard(name: "Main", bundle: nil)
    }

    func makeChatVC(from deepLink: PushDeepLink) -> UIViewController? {
        guard let roomId = deepLink.roomId, !roomId.isEmpty,
              let buyerId = deepLink.buyerId, !buyerId.isEmpty,
              let sellerId = deepLink.sellerId, !sellerId.isEmpty,
              let productId = deepLink.productId, !productId.isEmpty else {
            return nil
        }

        guard let chat = storyboard.instantiateViewController(
            withIdentifier: "ChatVC"
        ) as? ChatViewController else {
            assertionFailure("ChatVC not found in storyboard")
            return nil
        }

        chat.roomId = roomId
        chat.buyerId = buyerId
        chat.sellerId = sellerId
        chat.productId = productId

        let myId = LoginInfoUtil.getUserId()
        if myId.isEmpty { return nil }
        chat.currentUserId = myId

        return chat
    }

    func makeProductDetailVC(from deepLink: PushDeepLink) -> UIViewController? {
        guard let productIdStr = deepLink.productId,
              let pid = Int64(productIdStr), pid > 0 else {
            return nil
        }

        guard let detail = storyboard.instantiateViewController(
            withIdentifier: "ProductDetailVC"
        ) as? ProductDetailViewController else {
            assertionFailure("ProductDetailVC not found in storyboard")
            return nil
        }

        detail.productId = pid
        detail.productUserId = deepLink.sellerId ?? "0"
        detail.pushType = deepLink.type.rawValue
        detail.pushMsg = deepLink.msg

        return detail
    }

    func makeDashboardVC() -> UIViewController {
        if let vc = storyboard.instantiateViewController(withIdentifier: "DashboardVC") as? DashboardViewController {
            return vc
        }
        return DashboardViewController()
    }

    func makeMainTabBarVC() -> UIViewController {
        if let vc = storyboard.instantiateViewController(withIdentifier: "MainTabBarVC") as? MainTabBarController {
            return vc
        }
        return MainTabBarController()
    }
}
