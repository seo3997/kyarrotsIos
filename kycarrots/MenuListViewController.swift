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
    // 권한에 따라 동적으로 변경될 메뉴 데이터
    private var menuSections: [[MenuItem]] = []
    private let sectionTitles = ["", "고객지원"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDynamicMenu() // 권한별 메뉴 설정
        setupTableView()
    }
    // MARK: - 권한별 메뉴 구성 (Android의 applyMenuForRole 대응)
    private func setupDynamicMenu() {
        let userRole = LoginInfoUtil.getMemberCode() // 사용자 권한 가져오기
        
        var section0: [MenuItem] = []
        
        // 1. 권한별 메인 메뉴 구성
        switch userRole {
        case "ROLE_SELL", "ROLE_PROJ":
            // 판매자 및 도매업자는 대시보드 포함
            section0.append(.init(icon: "house", title: "대시보드", type: .dashboard))
            section0.append(.init(icon: "square.grid.2x2", title: "상품리스트", type: .products))
            section0.append(.init(icon: "gearshape", title: "설정", type: .settings))
            
        default:
            // 일반 구매자 (ROLE_BUYER 등)
            section0.append(.init(icon: "square.grid.2x2", title: "상품리스트", type: .products))
            section0.append(.init(icon: "gearshape", title: "설정", type: .settings))
        }
        
        // 2. 공통 고객지원 메뉴
        let section1: [MenuItem] = [
            .init(icon: "megaphone", title: "공지사항", type: .notice),
            .init(icon: "bubble.left.and.bubble.right", title: "문의하기", type: .inquiry),
            .init(icon: "doc.text", title: "약관 및 정책", type: .policy)
        ]
        
        self.menuSections = [section0, section1]
        self.tableView.reloadData()
    }
        
    private func setupTableView() {
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
        
        let loginNo = LoginInfoUtil.getUserNo()
        
        dismiss(animated: true) {
            guard let nav = navToUse else { return }
            
            switch selected.type {
                
            case .dashboard:
                nav.popToRootViewController(animated: true)
                
            case .products:
                // 권한에 따른 분기 처리 (Android applyMenuForRole 대응)
                if LoginInfoUtil.getMemberCode() == "ROLE_SELL" || LoginInfoUtil.getMemberCode() == "ROLE_PROJ" {
                    // 판매자/도매업자: 기존 상품리스트 뷰
                    let vc = ProductListViewController()
                    vc.title = selected.title
                    nav.pushViewController(vc, animated: true)
                } else {
                    // 나머지 (ROLE_BUYER 등): 메인 탭바 컨트롤러
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let mainTabVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarVC") as? MainTabBarController {
                            nav.pushViewController(mainTabVC, animated: true)
                    }
                }
            case .settings:
                let vc = SettingsViewController()
                vc.title = selected.title
                nav.pushViewController(vc, animated: true)
                
            case .notice:
                print("*****notice******")
                self.openWebMenu("notice", loginNo: loginNo)
                /*
                 let vc = NoticeViewController()
                 vc.title = selected.title
                 nav.pushViewController(vc, animated: true)
                 */
            case .inquiry:
                print("*****inquiry******")
                self.openWebMenu("discuss", loginNo: loginNo)
                /*
                 let vc = InquiryViewController()
                 vc.title = selected.title
                 nav.pushViewController(vc, animated: true)
                 */
            case .policy:
                print("*****inquiry******")
                self.openWebMenu("forum", loginNo: loginNo)
                /*
                 let vc = PolicyViewController()
                 vc.title = selected.title
                 nav.pushViewController(vc, animated: true)
                 */
            }
        }
    }
    
    func openWebMenu(_ type: String, loginNo: String) {
        let urlString: String
        let title: String
        
        switch type.lowercased() {
            
        case "notice":       // 공지사항
            urlString = Constants.BASE_URL +
            "front/board/selectPageListBoard.do?sch_bbs_se_code_m=10&ss_user_no=\(loginNo)"
            title = "공지사항"
            
        case "discuss":      // 문의하기
            urlString = Constants.BASE_URL +
            "front/board/selectPageListBoard.do?sch_bbs_se_code_m=20&ss_user_no=\(loginNo)"
            title = "문의하기"
            
        case "forum":        // 약관 및 정책
            urlString = Constants.BASE_URL + "link/join_terms.do"
            title = "약관 및 정책"
            
        default:
            return   // 잘못된 type이면 아무 것도 안 함
        }
        
        let vc = WebViewController.instantiate(urlString: urlString, title: title)

           // 기존 root Nav 에 push (ProductList랑 동일 패턴)
           dismiss(animated: true) {
               guard
                   let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let sceneDelegate = scene.delegate as? SceneDelegate,
                   let window = sceneDelegate.window,
                   let nav = window.rootViewController as? UINavigationController
               else { return }

               nav.pushViewController(vc, animated: true)
           }
    }
}
