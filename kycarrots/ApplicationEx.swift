import UIKit


extension UIApplication {
    var appCoordinator: AppCoordinator? {
        guard let scene = connectedScenes.first as? UIWindowScene,
              let delegate = scene.delegate as? SceneDelegate else { return nil }
        return delegate.appCoordinator
    }
}
