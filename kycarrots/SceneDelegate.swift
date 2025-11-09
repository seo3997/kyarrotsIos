import UIKit
import SideMenu

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var leftMenuNav: SideMenuNavigationController!

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        //let mainVC = MainViewController()
        let mainVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "DashboardVC")
        let nav = UINavigationController(rootViewController: mainVC)

        let menuVC = MenuListViewController()
        leftMenuNav = SideMenuNavigationController(rootViewController: menuVC)
        leftMenuNav.leftSide = true
        leftMenuNav.setNavigationBarHidden(true, animated: false)

        SideMenuManager.default.leftMenuNavigationController = leftMenuNav
        SideMenuManager.default.addPanGestureToPresent(toView: nav.navigationBar)
        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: nav.view, forMenu: .left)

        leftMenuNav.presentationStyle = .menuSlideIn
        leftMenuNav.menuWidth = min(300, UIScreen.main.bounds.width * 0.8)
        leftMenuNav.statusBarEndAlpha = 0

        window?.rootViewController = nav
        window?.makeKeyAndVisible()
    }
}
