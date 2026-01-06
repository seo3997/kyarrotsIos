import UIKit

extension UIView {

    func applyCardStyle(
        radius: CGFloat = 12,
        shadowOpacity: Float = 0.1,
        shadowOffset: CGSize = CGSize(width: 0, height: 2),
        shadowRadius: CGFloat = 6,
        backgroundColor: UIColor = .white
    ) {
        layer.cornerRadius = radius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowOffset = shadowOffset
        layer.shadowRadius = shadowRadius
        layer.masksToBounds = false
        self.backgroundColor = backgroundColor
    }
}
