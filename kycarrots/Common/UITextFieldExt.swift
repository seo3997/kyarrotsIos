import UIKit

extension UITextField {
    @IBInspectable var maxLength: Int {
        get {
            // 연관 객체로 저장된 값을 불러옴 (기본값은 Int 최대치)
            return objc_getAssociatedObject(self, &maxLengthKey) as? Int ?? Int.max
        }
        set {
            // 값을 설정하고, 글자가 바뀔 때 감지할 타겟 추가
            objc_setAssociatedObject(self, &maxLengthKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            addTarget(self, action: #selector(limitLength), for: .editingChanged)
        }
    }

    @objc private func limitLength() {
        guard let text = self.text else { return }
        if text.count > maxLength {
            let index = text.index(text.startIndex, offsetBy: maxLength)
            self.text = String(text[..<index])
        }
    }
}

private var maxLengthKey: UInt8 = 0
