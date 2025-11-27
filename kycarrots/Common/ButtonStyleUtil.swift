import UIKit

extension UIButton {
    /// iOS15+ Configuration 버튼에서도 폰트를 적용하는 공통 함수
    func setFont(size: CGFloat, weight: UIFont.Weight = .medium) {
        var config = self.configuration

        config?.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: size, weight: weight)
                return outgoing
            }

        self.configuration = config
    }
}
