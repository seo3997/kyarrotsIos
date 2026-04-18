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
        let viewModel = LoginViewModel(service: AppServiceProvider.shared)
        viewModel.onLoginSuccess = { [weak self] in
            self?.showIntro(launchDeepLink: pendingDeepLink, animated: true)
        }
        viewModel.onShowOnboarding = { [weak self] provider, pid, name, email, url in
            self?.showOnboarding(provider: provider, pid: pid, name: name, email: email, url: url, pending: pendingDeepLink)
        }
        viewModel.onShowMembership = { [weak self] in
            self?.showTermsAgree()
        }
        viewModel.onShowFindAccount = { [weak self] in
            self?.showFindAccount()
        }
        
        let rootView = LoginSwiftUIView(viewModel: viewModel)
        let vc = SideMenuRestrictedHostingController(rootView: rootView)
        nav.setViewControllers([vc], animated: true)
    }

    func showOnboarding(provider: String, pid: String, name: String, email: String, url: String, pending: PushDeepLink?) {
        let viewModel = OnboardingViewModel(
            service: AppServiceProvider.shared,
            provider: provider,
            providerUserId: pid,
            presetEmail: email,
            presetNickname: name
        )
        let rootView = OnboardingSwiftUIView(viewModel: viewModel) { [weak self] in
            self?.showIntro(launchDeepLink: pending, animated: true)
        }
        let vc = SideMenuRestrictedHostingController(rootView: rootView)
        nav.pushViewController(vc, animated: true)
    }

    func showFindAccount() {
        let viewModel = FindAccountViewModel(service: AppServiceProvider.shared)
        let rootView = FindAccountSwiftUIView(viewModel: viewModel)
        let vc = SideMenuRestrictedHostingController(rootView: rootView)
        nav.pushViewController(vc, animated: true)
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
        case .order:
            if let orderId = deepLink.targetId {
                if memberCode == "ROLE_SELL" || memberCode == "ROLE_PROJ" || memberCode == "ROLE_ADMIN" {
                    showOrderMgtDetail(orderId: orderId)
                } else {
                    showOrderDetail(orderId: orderId)
                }
            }
        case .sys:
            showNotificationList()
        }
    }

    func showProductDetail(pid: Int64, userId: String, title: String, initialTab: Int = 0) {
        let vc = makeProductDetailVC(productId: pid, userId: userId, title: title, initialTab: initialTab)
        nav.pushViewController(vc, animated: true)
    }
    
    func popBack() {
        nav.popViewController(animated: true)
    }

    func popToRoot() {
        nav.popToRootViewController(animated: true)
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
            self?.showNotificationList()
        }
        
        let hostingVC = UIHostingController(rootView: rootView)
        hostingVC.navigationItem.title = "내 등록 매물"
        hostingVC.addLeftMenuButton() // ✅ 햄버거 메뉴 버튼 추가 (뒤로가기 숨김)
        nav.pushViewController(hostingVC, animated: true)
    }

    func showMembership() {
        let viewModel = MembershipViewModel(service: AppServiceProvider.shared)
        let rootView = MembershipSwiftUIView(viewModel: viewModel) { [weak self] in
            self?.showIntro(launchDeepLink: nil, animated: true)
        }
        let vc = UIHostingController(rootView: rootView)
        // vc.navigationItem.title = "회원가입" // SwiftUI internal title is used
        nav.pushViewController(vc, animated: true)
    }

    func showTermsAgree() {
        let rootView = TermsAgreeSwiftUIView(
            onNext: { [weak self] in
                self?.showMembership()
            },
            onCancel: { [weak self] in
                self?.nav.popViewController(animated: true)
            },
            onShowZoom: { [weak self] title, url in
                self?.showTermsZoom(title: title, url: URL(string: url))
            }
        )
        let vc = UIHostingController(rootView: rootView)
        nav.pushViewController(vc, animated: true)
    }

    func showTermsZoom(title: String, url: URL?) {
        let rootView = TermsZoomSwiftUIView(title: title, url: url, html: nil)
        let vc = UIHostingController(rootView: rootView)
        nav.pushViewController(vc, animated: true)
    }

    func showNotificationList() {
        let viewModel = NotificationListViewModel()
        var rootView = NotificationListSwiftUIView(viewModel: viewModel) { [weak self] item in
            guard let self = self else { return }
            
            switch item.type {
            case "chat", "CHAT":
                if let roomId = item.targetId, !roomId.isEmpty {
                    // roomId에서 나머지 정보 추출 (productId_buyerId_branchId 형태)
                    let components = roomId.components(separatedBy: "_")
                    if components.count >= 3 {
                        self.openChat(roomId: roomId, buyerId: components[1], branchId: components[2], productId: components[0])
                    }
                }
            case "product", "PRODUCT", "PRODUCT_REGISTERED", "PRODUCT_APPROVED", "PRODUCT_REJECTED", "PRODUCT_INQUIRY", "PRODUCT_REVIEW", "PRODUCT_QNA":
                if let pidStr = item.targetId, let pid = Int64(pidStr) {
                    var initialTab = 0
                    let upperType = item.type.uppercased()
                    if upperType.contains("REVIEW") {
                        initialTab = 1
                    } else if upperType.contains("INQUIRY") || upperType.contains("QNA") {
                        initialTab = 2
                    }
                    self.showProductDetail(pid: pid, userId: "0", title: "상품 상세", initialTab: initialTab)
                }
            case let t where t.uppercased().contains("ORDER"):
                if let orderId = item.targetId {
                    // ✅ memberCode 확인 로직 수정 (로그인 정보 유틸 사용)
                    let memberCode = LoginInfoUtil.getMemberCode()
                    if memberCode == "ROLE_SELL" || memberCode == "ROLE_PROJ" || memberCode == "ROLE_ADMIN" {
                        self.showOrderMgtDetail(orderId: orderId)
                    } else {
                        self.showOrderDetail(orderId: orderId)
                    }
                }
            default:
                if let deeplink = item.deeplink, let url = URL(string: deeplink) {
                    UIApplication.shared.open(url)
                }
            }
        }
        
        let vc = UIHostingController(rootView: rootView)
        vc.navigationItem.title = "알림 리스트"
        nav.pushViewController(vc, animated: true)
    }

    func showOrderDetail(orderId: String) {
        let rootView = OrderDetailView(orderId: orderId)
        let vc = SideMenuRestrictedHostingController(rootView: rootView)
        vc.navigationItem.title = "주문 상세 정보"
        nav.pushViewController(vc, animated: true)
    }
    
}

// MARK: - Storyboard Factory
private extension AppCoordinator {

    var storyboard: UIStoryboard {
        UIStoryboard(name: "Main", bundle: nil)
    }

    func makeChatVC(from deepLink: PushDeepLink) -> UIViewController? {
        guard let roomId = deepLink.targetId, !roomId.isEmpty else {
            return nil
        }
        
        let parts = roomId.components(separatedBy: "_")
        var productId = ""
        var buyerId = ""
        var branchId = ""
        
        if parts.count >= 3 {
             productId = parts[0]
             buyerId = parts[1]
             branchId = parts[2]
        } else {
            // fallback 혹은 예외처리
            return nil
        }

        let myId = LoginInfoUtil.getUserId()
        if myId.isEmpty { return nil }

        let viewModel = ChatViewModel(
            roomId: roomId,
            currentUserId: myId,
            buyerId: buyerId,
            branchId: branchId
        )
        let rootView = ChatSwiftUIView(viewModel: viewModel)
        let vc = UIHostingController(rootView: rootView)
        return vc
    }

    func makeProductDetailVC(from deepLink: PushDeepLink) -> UIViewController? {
        guard let productIdStr = deepLink.targetId,
              let pid = Int64(productIdStr), pid > 0 else {
            return nil
        }
        // Android equivalent: AdDetailActivity.EXTRA_PRODUCT_ID
        return makeProductDetailVC(productId: pid, userId: "0", title: "상품 상세", initialTab: 0)
    }

    func makeProductDetailVC(productId: Int64, userId: String, title: String, initialTab: Int = 0) -> UIViewController {
        let viewModel = ProductDetailViewModel(productId: productId, initialTab: initialTab)
        var rootView = ProductDetailSwiftUIView(viewModel: viewModel) { [weak self] pid in
            // Handle Edit
            let vc = MakeAdMainViewController(service: AppServiceProvider.shared, productId: String(pid))
            self?.nav.pushViewController(vc, animated: true)
        } onOpenChat: { [weak self] room in
            // Handle Open Chat
            self?.openChat(roomId: room.roomId, buyerId: room.buyerId, branchId: room.branchId, productId: String(room.productId))
        } onShowBuyerSelection: { [weak self] rooms in
            // Show Buyer Selection Action Sheet
            let alert = UIAlertController(title: "구매자를 선택하세요", message: nil, preferredStyle: .actionSheet)
            for (i, r) in rooms.enumerated() {
                alert.addAction(UIAlertAction(title: "구매자 \(i+1): \(r.buyerId)", style: .default) { _ in
                    self?.openChat(roomId: r.roomId, buyerId: r.buyerId, branchId: r.branchId, productId: String(r.productId))
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

    private func openChat(roomId: String, buyerId: String, branchId: String, productId: String) {
        let myId = LoginInfoUtil.getUserId()
        if myId.isEmpty { return }

        let viewModel = ChatViewModel(
            roomId: roomId,
            currentUserId: myId,
            buyerId: buyerId,
            branchId: branchId
        )
        let rootView = ChatSwiftUIView(viewModel: viewModel)
        let vc = UIHostingController(rootView: rootView)
        vc.navigationItem.title = viewModel.otherId
        nav.pushViewController(vc, animated: true)
    }

    func makeDashboardVC() -> UIViewController {
        var rootView = DashboardSwiftUIView()
        rootView.onShowNotifications = { [weak self] in
            self?.showNotificationList()
        }
        rootView.onToggleMenu = { [weak self] in
            guard let self = self, let menu = SideMenuManager.default.leftMenuNavigationController else { return }
            self.nav.present(menu, animated: true)
        }
        rootView.onSelectOrder = { [weak self] order in
            self?.showOrderMgtDetail(orderId: order.orderId)
        }
        rootView.onShowOrderMgt = { [weak self] in
            self?.showOrderManagement()
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
        rootView.onSelectOrder = { [weak self] orderId in
            self?.showOrderDetail(orderId: orderId)
        }
        rootView.onShowNotifications = { [weak self] in
            self?.showNotificationList()
        }
        let hostingVC = UIHostingController(rootView: rootView)
        hostingVC.navigationItem.title = "상품리스트"
        hostingVC.addLeftMenuButton() // ✅ 햄버거 메뉴 버튼 추가
        return hostingVC
    }
    
    func showOrderMgtDetail(orderId: String) {
        let rootView = OrderMgtDetailView(orderId: orderId)
        let vc = UIHostingController(rootView: rootView)
        vc.navigationItem.title = "주문 상세 관리"
        nav.pushViewController(vc, animated: true)
    }

    func showOrderManagement() {
        var rootView = OrderManagementView()
        rootView.onToggleMenu = { [weak self] in
            guard let self = self, let menu = SideMenuManager.default.leftMenuNavigationController else { return }
            self.nav.present(menu, animated: true)
        }
        rootView.onShowNotifications = { [weak self] in
            self?.showNotificationList()
        }
        let vc = UIHostingController(rootView: rootView)
        vc.navigationItem.title = "주문 통합 관리"
        nav.pushViewController(vc, animated: true)
    }
}
