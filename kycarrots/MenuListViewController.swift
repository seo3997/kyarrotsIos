import UIKit

enum MenuItemType {
    case dashboard
    case products
    case favorites
    case settings
}

struct MenuItem {
    let icon: String
    let title: String
    let type: MenuItemType
}

final class MenuListViewController: UITableViewController {
    private let items: [MenuItem] = [
        .init(icon: "house",            title: "대시보드",   type: .dashboard),
        .init(icon: "square.grid.2x2",  title: "상품리스트", type: .products),
        .init(icon: "star",             title: "Favorites",  type: .favorites),
        .init(icon: "gearshape",        title: "설정",       type: .settings),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.contentInset.top = 40

        let header = MenuHeaderView()
        header.frame = CGRect(x: 0, y: 0, width: 0, height: 120)
        tableView.tableHeaderView = header
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let item = items[indexPath.row]
        cell.imageView?.image = UIImage(systemName: item.icon)
        cell.textLabel?.text = item.title
        cell.backgroundColor = .clear
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // 메뉴는 모달로 떠있고, presentingViewController가 보통 UINavigationController
        guard let presenter = presentingViewController else {
            dismiss(animated: true, completion: nil)
            return
        }

        // TabBarController일 수도 있으니, 실제로 push할 UINavigationController를 찾아준다
        let navToUse: UINavigationController? = {
            if let nav = presenter as? UINavigationController {
                return nav
            } else if let tab = presenter as? UITabBarController {
                if let nav = tab.selectedViewController as? UINavigationController { return nav }
                if let nav = tab.viewControllers?.first as? UINavigationController { return nav }
            }
            return nil
        }()

        let selected = items[indexPath.row]

        dismiss(animated: true) {
            guard let nav = navToUse else { return }

            switch selected.type {
            case .dashboard:
                // 대시보드는 루트로 복귀
                let vc = UIStoryboard(name: "Main", bundle: nil)
                    .instantiateViewController(withIdentifier: "DashboardVC") as! DashboardViewController
                //let vc = DashboardViewController()
                nav.pushViewController(vc, animated: true)
                
                //nav.popToRootViewController(animated: true)

            case .products:
                // 상품 리스트 화면으로 이동 (예시 VC)
                let vc = ProductListViewController()
                vc.title = selected.title
                nav.pushViewController(vc, animated: true)

            case .favorites:
                let vc = FavoritesViewController()
                vc.title = selected.title
                nav.pushViewController(vc, animated: true)

            case .settings:
                let vc = SettingsViewController()
                vc.title = selected.title
                nav.pushViewController(vc, animated: true)
            }
        }
    }
}

final class MenuHeaderView: UIView {
    private let nameLabel = UILabel()
    private let subLabel = UILabel()
    private let avatar = UIImageView(image: UIImage(systemName: "person.crop.circle"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        avatar.contentMode = .scaleAspectFit
        avatar.tintColor = .label

        nameLabel.text = "SooHyun"
        nameLabel.font = .boldSystemFont(ofSize: 20)
        subLabel.text = "soohyoun@example.com"
        subLabel.textColor = .secondaryLabel
        subLabel.font = .systemFont(ofSize: 13)

        let vstack = UIStackView(arrangedSubviews: [avatar, nameLabel, subLabel])
        vstack.axis = .vertical
        vstack.alignment = .leading
        vstack.spacing = 8

        addSubview(vstack)
        vstack.translatesAutoresizingMaskIntoConstraints = false
        avatar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vstack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            vstack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            vstack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            vstack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12),
            avatar.heightAnchor.constraint(equalToConstant: 40),
            avatar.widthAnchor.constraint(equalTo: avatar.heightAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
