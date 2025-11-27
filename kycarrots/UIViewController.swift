import UIKit

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
}
