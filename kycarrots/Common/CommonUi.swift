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
    
    func applyTermsBoxStyle() {
          backgroundColor = .white
          layer.cornerRadius = 12
          layer.borderWidth = 1
          layer.borderColor = UIColor.systemGray3.cgColor
          layer.masksToBounds = true
      }
    
    func applyFormFieldStyle(
          radius: CGFloat = 12,
          borderColor: UIColor = .systemGray4,
          borderWidth: CGFloat = 1,
          backgroundColor: UIColor = .white
      ) {
          layer.cornerRadius = radius
          layer.borderWidth = borderWidth
          layer.borderColor = borderColor.cgColor
          layer.masksToBounds = true
          self.backgroundColor = backgroundColor
      }
}

extension UITextField {
    func setLeftPadding(_ v: CGFloat) {
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: v, height: 1))
        leftView = pad
        leftViewMode = .always
    }
}
