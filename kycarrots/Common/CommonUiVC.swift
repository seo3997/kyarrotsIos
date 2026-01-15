import UIKit

extension UIViewController {

    func showAlert(title: String = "알림", _ message: String, onOK: (() -> Void)? = nil) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "확인", style: .default) { _ in onOK?() })
        present(a, animated: true)
    }
}
