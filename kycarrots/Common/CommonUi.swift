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

    func styleTextField() {
        borderStyle = .none
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        backgroundColor = .white
        setLeftPadding(14)
        heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

}

extension UIButton {

    func applyPillStyle(
        radius: CGFloat = 12,
        borderColor: UIColor = .systemGray4,
        borderWidth: CGFloat = 1,
        backgroundColor: UIColor = .white,
        height: CGFloat = 48,
        horizontalPadding: CGFloat = 14
    ) {
        contentHorizontalAlignment = .left
        layer.cornerRadius = radius
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        self.backgroundColor = backgroundColor

        contentEdgeInsets = UIEdgeInsets(
            top: 0,
            left: horizontalPadding,
            bottom: 0,
            right: horizontalPadding
        )

        // 중복 constraint 방지
        if !constraints.contains(where: { $0.firstAttribute == .height && $0.relation == .equal }) {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
}
