import UIKit

enum MenuItemType {
    case dashboard
    case products
    case settings

    case notice
    case inquiry
    case policy
}

struct MenuItem {
    let icon: String
    let title: String
    let type: MenuItemType
}

final class MenuListViewController: UITableViewController {

    // 안드로이드 menu.xml 처럼 섹션 2개
    private let menuSections: [[MenuItem]] = [
        // SECTION 0 : 일반 메뉴
        [
            .init(icon: "house",             title: "대시보드",    type: .dashboard),
            .init(icon: "square.grid.2x2",   title: "상품리스트",  type: .products),
            .init(icon: "gearshape",         title: "설정",        type: .settings),
        ],

        // SECTION 1 : 고객지원
        [
            .init(icon: "megaphone",         title: "공지사항",    type: .notice),
            .init(icon: "bubble.left.and.bubble.right", title: "문의하기",  type: .inquiry),
            .init(icon: "doc.text",          title: "약관 및 정책", type: .policy),
        ]
    ]

    private let sectionTitles = [
        "",          // 첫 섹션 제목 없음
        "고객지원"    // 두 번째 섹션 제목
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
                avatar.heightAnchor.constraint(equalToConstant: 40),
                avatar.widthAnchor.constraint(equalTo: avatar.heightAnchor)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    // MARK: - Table Sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return menuSections.count
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return menuSections[section].count
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    override func tableView(_ tableView: UITableView,
                            willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = .boldSystemFont(ofSize: 13)
        header.textLabel?.textColor = .secondaryLabel
        header.textLabel?.frame = header.frame
    }

    // MARK: - Cell
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)

        let item = menuSections[indexPath.section][indexPath.row]

        cell.imageView?.image = UIImage(systemName: item.icon)
        cell.textLabel?.text = item.title
        cell.backgroundColor = .clear

        return cell
    }

    // MARK: - Menu Selection
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        guard let presenter = presentingViewController else {
            dismiss(animated: true)
            return
        }

        let navToUse: UINavigationController? = {
            if let nav = presenter as? UINavigationController { return nav }
            if let tab = presenter as? UITabBarController {
                if let nav = tab.selectedViewController as? UINavigationController { return nav }
                if let firstNav = tab.viewControllers?.first as? UINavigationController { return firstNav }
            }
            return nil
        }()

        let selected = menuSections[indexPath.section][indexPath.row]

        dismiss(animated: true) {
            guard let nav = navToUse else { return }

            switch selected.type {

            case .dashboard:
                nav.popToRootViewController(animated: true)

            case .products:
                let vc = ProductListViewController()
                vc.title = selected.title
                nav.pushViewController(vc, animated: true)

            case .settings:
                let vc = SettingsViewController()
                vc.title = selected.title
                nav.pushViewController(vc, animated: true)

            case .notice:
                print("*****notice******")
                /*
                let vc = NoticeViewController()
                vc.title = selected.title
                nav.pushViewController(vc, animated: true)
                */
            case .inquiry:
                print("*****inquiry******")
                /*
                let vc = InquiryViewController()
                vc.title = selected.title
                nav.pushViewController(vc, animated: true)
                */
            case .policy:
                print("*****inquiry******")
                /*
                let vc = PolicyViewController()
                vc.title = selected.title
                nav.pushViewController(vc, animated: true)
                */
            }
        }
    }
}
