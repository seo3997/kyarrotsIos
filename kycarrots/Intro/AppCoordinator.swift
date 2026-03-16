import UIKit
import SideMenu
import SwiftUI

final class AppCoordinator {
    static var shared: AppCoordinator? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let delegate = scene.delegate as? SceneDelegate else { return nil }
        return delegate.appCoordinator
    }
    
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
        vc.coordinator = self               
        vc.pendingDeepLink = pendingDeepLink
        nav.setViewControllers([vc], animated: true)
    }

    func showHome(memberCode: String, deepLink: PushDeepLink?) {

        // ✅ 1) 기본 랜딩을 "항상" 루트로 세팅 (뒤로가기/메뉴/탭 구조 보존)
        let root: UIViewController
        if memberCode == "ROLE_SELL" || memberCode == "ROLE_PROJ" {
            root = makeDashboardVC()
        } else {
            root = makeMainTabBarVC()
        }

        // 루트가 이미 같은 타입이면 굳이 다시 세팅하지 않아도 되지만,
        // 푸시로 "Intro -> Home" 흐름에서는 그냥 세팅해도 문제 없음.
        nav.setViewControllers([root], animated: true)

        // ✅ 2) 딥링크가 있으면 루트 위로 push (뒤로가기 생성)
        guard let deepLink else { return }

        switch deepLink.type {
        case .chat:
            if let chat = makeChatVC(from: deepLink) {
                nav.pushViewController(chat, animated: true)
            }
        case .product:
            if let detail = makeProductDetailVC(from: deepLink) {
                nav.pushViewController(detail, animated: true)
            }
        }
    }

    func showProductDetail(pid: Int64, userId: String, title: String) {
        let vc = makeProductDetailVC(productId: pid, userId: userId, title: title)
        nav.pushViewController(vc, animated: true)
    }

    func showIntro(launchDeepLink: PushDeepLink? = nil, animated: Bool = true) {
        print("coordinator nav =", nav)
        print("window.rootVC =", window.rootViewController as Any)
        
        let intro = IntroViewController(
            service: AppServiceProvider.shared,
            coordinator: self,
            launchDeepLink: launchDeepLink
        )
        nav.setViewControllers([intro], animated: animated)
        /*
        // ✅ 핵심: 루트를 강제로 nav로 맞춘다
         window.rootViewController = nav
         window.makeKeyAndVisible()

         if animated {
             UIView.transition(with: window,
                               duration: 0.25,
                               options: .transitionCrossDissolve,
                               animations: nil)
         }
         */
    }
    
    func showProductList() {
        var rootView = ProductListSwiftUIView()
        rootView.onSelectProduct = { [weak self] item in
            guard let self = self else { return }
            let pid = Int64(item.productId ?? "") ?? 0
            self.showProductDetail(pid: pid, userId: item.userId ?? "", title: item.title ?? "")
        }
        rootView.onAddProduct = { [weak self] in
            guard let self = self else { return }
            let vc = MakeAdMainViewController(service: AppServiceProvider.shared)
            self.nav.pushViewController(vc, animated: true)
        }
        rootView.onShowNotifications = { [weak self] in
            guard let self = self else { return }
            let vc = NotificationListViewController()
            self.nav.pushViewController(vc, animated: true)
        }
        
        let hostingVC = UIHostingController(rootView: rootView)
        hostingVC.navigationItem.title = "내 등록 매물"
        hostingVC.addLeftMenuButton() // ✅ 햄버거 메뉴 버튼 추가 (뒤로가기 숨김)
        nav.pushViewController(hostingVC, animated: true)
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
        return makeProductDetailVC(productId: pid, userId: deepLink.sellerId ?? "0", title: deepLink.msg ?? "")
    }

    func makeProductDetailVC(productId: Int64, userId: String, title: String) -> UIViewController {
        let viewModel = ProductDetailViewModel(productId: productId)
        var rootView = ProductDetailSwiftUIView(viewModel: viewModel) { [weak self] pid in
            // Handle Edit
            let vc = MakeAdMainViewController(service: AppServiceProvider.shared, productId: String(pid))
            self?.nav.pushViewController(vc, animated: true)
        } onOpenChat: { [weak self] room in
            // Handle Open Chat
            self?.openChat(roomId: room.roomId, buyerId: room.buyerId, sellerId: room.sellerId, productId: String(room.productId))
        } onShowBuyerSelection: { [weak self] rooms in
            // Show Buyer Selection Action Sheet
            let alert = UIAlertController(title: "구매자를 선택하세요", message: nil, preferredStyle: .actionSheet)
            for (i, r) in rooms.enumerated() {
                alert.addAction(UIAlertAction(title: "구매자 \(i+1): \(r.buyerId)", style: .default) { _ in
                    self?.openChat(roomId: r.roomId, buyerId: r.buyerId, sellerId: r.sellerId, productId: String(r.productId))
                })
            }
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            self?.nav.present(alert, animated: true)
        } onShowBuyerPickSheet: { [weak self] (buyers, onPick) in
            // Show Buyer Pick for Completion
            let alert = UIAlertController(title: "판매완료 처리 — 구매자 선택", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "선택 안함", style: .default) { _ in onPick(nil) })
            buyers.forEach { b in
                alert.addAction(UIAlertAction(title: "\(b.buyerId)/\(b.buyerNm)", style: .default) { _ in onPick(b) })
            }
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            self?.nav.present(alert, animated: true)
        } onAskRejectReason: { [weak self] onDone in
            // Ask Reject Reason Alert
            let alert = UIAlertController(title: "반려 사유 입력", message: nil, preferredStyle: .alert)
            alert.addTextField { tf in tf.placeholder = "반려 사유를 입력하세요" }
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                let reason = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                onDone(reason)
            })
            self?.nav.present(alert, animated: true)
        } onShowAlert: { [weak self] (title, message) in
            let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "확인", style: .default))
            self?.nav.present(a, animated: true)
        }

        let vc = UIHostingController(rootView: rootView)
        vc.navigationItem.title = title.isEmpty ? "상품 상세" : title
        return vc
    }

    private func openChat(roomId: String, buyerId: String, sellerId: String, productId: String) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "ChatVC") as? ChatViewController else { return }
        vc.roomId = roomId
        vc.buyerId = buyerId
        vc.sellerId = sellerId
        vc.productId = productId
        vc.currentUserId = LoginInfoUtil.getUserId()
        nav.pushViewController(vc, animated: true)
    }

    func makeDashboardVC() -> UIViewController {
        var rootView = DashboardSwiftUIView()
        rootView.onShowNotifications = { [weak self] in
            let vc = NotificationListViewController()
            self?.nav.pushViewController(vc, animated: true)
        }
        rootView.onAddProduct = { [weak self] in
            let vc = MakeAdMainViewController(service: AppServiceProvider.shared)
            self?.nav.pushViewController(vc, animated: true)
        }
        rootView.onSelectProduct = { [weak self] item in
            let pid = Int64(item.productId) ?? 0
            self?.showProductDetail(pid: pid, userId: item.userId, title: item.title)
        }
        rootView.onShowMore = { [weak self] in
            self?.showProductList()
        }
        rootView.onShowApproval = { [weak self] in
            self?.showProductList()
        }
        
        let vc = UIHostingController(rootView: rootView)
        vc.navigationItem.title = "대시보드"
        vc.addLeftMenuButton() // ✅ 햄버거 메뉴 버튼 추가
        return vc
    }

    func makeMainTabBarVC() -> UIViewController {
        var rootView = MainTabView()
        rootView.onSelectProduct = { [weak self] item in
            guard let self = self else { return }
            let pid = Int64(item.productId ?? "") ?? 0
            self.showProductDetail(pid: pid, userId: item.userId ?? "", title: item.title ?? "")
        }
        let hostingVC = UIHostingController(rootView: rootView)
        hostingVC.navigationItem.title = "상품리스트"
        hostingVC.addLeftMenuButton() // ✅ 햄버거 메뉴 버튼 추가
        return hostingVC
    }
}
