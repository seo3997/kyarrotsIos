import UIKit

@MainActor
final class NotificationBadgeManager {
    static let shared = NotificationBadgeManager()
    private init() {}

    private var badgeLabel = UILabel()
    private weak var installedNavBar: UINavigationBar?
    private(set) var currentCount: Int = 0

    // MARK: - Install

    func installIfNeeded(on navBar: UINavigationBar) {
        if installedNavBar === navBar, badgeLabel.superview != nil { return }

        badgeLabel.removeFromSuperview()
        installedNavBar = navBar

        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.backgroundColor = .systemRed
        badgeLabel.textColor = .white
        badgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 9
        badgeLabel.clipsToBounds = true
        badgeLabel.isHidden = true

        navBar.addSubview(badgeLabel)
        navBar.bringSubviewToFront(badgeLabel)

        NSLayoutConstraint.activate([
            badgeLabel.heightAnchor.constraint(equalToConstant: 18),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
            badgeLabel.trailingAnchor.constraint(equalTo: navBar.trailingAnchor, constant: -12),
            badgeLabel.topAnchor.constraint(equalTo: navBar.topAnchor, constant: 6),
        ])
    }

    // MARK: - Update

    func updateCount(_ count: Int) {
        currentCount = count

        if count <= 0 {
            badgeLabel.isHidden = true
            badgeLabel.text = nil
        } else {
            badgeLabel.isHidden = false
            badgeLabel.text = count > 99 ? "99+" : "\(count)"
        }
    }

    func hide() {
        badgeLabel.isHidden = true
    }

    func remove() {
        badgeLabel.removeFromSuperview()
        installedNavBar = nil
    }
}
