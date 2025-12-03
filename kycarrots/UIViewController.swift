import UIKit
import SideMenu

extension UIViewController {

    /// rootViewController를 다른 VC로 교체해주는 공통 함수
    func switchRoot(to viewController: UIViewController,
                    animated: Bool = true) {

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = scene.delegate as? SceneDelegate,
              let window = sceneDelegate.window else {
            return
        }

        let nav = UINavigationController(rootViewController: viewController)
        window.rootViewController = nav

        window.makeKeyAndVisible()

        if animated {
            UIView.transition(with: window,
                              duration: 0.3,
                              options: .transitionFlipFromRight,
                              animations: nil,
                              completion: nil)
        }
    }
    
    /// 모든 화면에서 '뒤로가기 제거 + 햄버거 버튼' 표시
      func addLeftMenuButton() {

          // 자동 뒤로가기 버튼 숨김
          navigationItem.hidesBackButton = true

          // 햄버거 버튼 추가
          let button = UIBarButtonItem(
              image: UIImage(systemName: "line.3.horizontal"),
              style: .plain,
              target: self,
              action: #selector(openSideMenu)
          )
          navigationItem.leftBarButtonItem = button
      }

      @objc private func openSideMenu() {
          guard let menuNav = SideMenuManager.default.leftMenuNavigationController else { return }
          present(menuNav, animated: true)
      }
}
