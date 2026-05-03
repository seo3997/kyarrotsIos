import UIKit
import SwiftUI
import SideMenu

enum MenuItemType {
    case dashboard
    case products
    case settings
    case notice
    case inquiry
    case policy
    case orderManagement
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
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupDynamicMenu() // 권한 및 메뉴 갱신
        updateHeaderInfo() // 유저 정보(이름, 이메일) 갱신
    }
    // MARK: - 권한별 메뉴 구성 (Android의 applyMenuForRole 대응)
    private func setupDynamicMenu() {
        let userRole = LoginInfoUtil.getMemberCode() // 사용자 권한 가져오기
        
        var section0: [MenuItem] = []
        
        // 1. 권한별 메인 메뉴 구성
        switch userRole {
        case "ROLE_SELL", "ROLE_PROJ":
            // 판매자 및 도매업자는 대시보드 및 주문관리 포함
            section0.append(.init(icon: "house", title: "대시보드", type: .dashboard))
            section0.append(.init(icon: "square.grid.2x2", title: "상품리스트", type: .products))
            section0.append(.init(icon: "cart", title: "주문관리", type: .orderManagement))
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
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.contentInset.top = 20
        tableView.rowHeight = 54 // 행 높이 고정으로 통일감 부여
        
        // 헤더 뷰 최초 설정
        updateHeaderInfo()
    }
    
    private func updateHeaderInfo() {
        let header = MenuHeaderView()
        header.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 140) // 높이 약간 늘림
        tableView.tableHeaderView = header
    }

    final class MenuHeaderView: UIView {
        private let nameLabel = UILabel()
        private let subLabel = UILabel()
        private let avatar = UIImageView()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupUI()
        }
        
        private func setupUI() {
            backgroundColor = .white
            
            avatar.contentMode = .scaleAspectFill
            avatar.clipsToBounds = true
            avatar.layer.cornerRadius = 30
            avatar.backgroundColor = .systemGray6
            avatar.layer.borderWidth = 1
            avatar.layer.borderColor = UIColor.systemGray5.cgColor
            
            if let localImage = ProfileImageUtil.getLocalProfileImage() {
                avatar.image = localImage
            } else {
                avatar.image = UIImage(systemName: "person.crop.circle.fill")
                avatar.tintColor = .systemGray3
            }
            
            nameLabel.text = LoginInfoUtil.getUserNm() ?? "로그인 필요"
            nameLabel.font = .systemFont(ofSize: 18, weight: .bold)
            nameLabel.textColor = .label
            
            subLabel.text = LoginInfoUtil.getUserId() ?? "이메일 정보 없음"
            subLabel.textColor = .secondaryLabel
            subLabel.font = .systemFont(ofSize: 13)
            
            let labelStack = UIStackView(arrangedSubviews: [nameLabel, subLabel])
            labelStack.axis = .vertical
            labelStack.alignment = .center
            labelStack.spacing = 4
            
            let mainStack = UIStackView(arrangedSubviews: [avatar, labelStack])
            mainStack.axis = .vertical
            mainStack.alignment = .center
            mainStack.spacing = 10
            
            addSubview(mainStack)
            mainStack.translatesAutoresizingMaskIntoConstraints = false
            avatar.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                mainStack.centerXAnchor.constraint(equalTo: centerXAnchor),
                mainStack.centerYAnchor.constraint(equalTo: centerYAnchor),
                avatar.widthAnchor.constraint(equalToConstant: 70),
                avatar.heightAnchor.constraint(equalToConstant: 70)
            ])
            
            // 하단 구분선
            let line = UIView()
            line.backgroundColor = .systemGray6
            addSubview(line)
            line.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                line.leadingAnchor.constraint(equalTo: leadingAnchor),
                line.trailingAnchor.constraint(equalTo: trailingAnchor),
                line.bottomAnchor.constraint(equalTo: bottomAnchor),
                line.heightAnchor.constraint(equalToConstant: 1)
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
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if sectionTitles[section].isEmpty { return nil }
        
        let headerView = UIView()
        let label = UILabel()
        label.text = sectionTitles[section]
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .secondaryLabel
        headerView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sectionTitles[section].isEmpty ? 0 : 40
    }
    
    // MARK: - Cell
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: "MenuCell")
        let item = menuSections[indexPath.section][indexPath.row]
        
        // 아이콘 설정
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        cell.imageView?.image = UIImage(systemName: item.icon, withConfiguration: config)
        cell.imageView?.tintColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0) // 진한 네이비/그레이 톤
        
        // 텍스트 설정
        cell.textLabel?.text = item.title
        cell.textLabel?.font = .systemFont(ofSize: 16)
        cell.textLabel?.textColor = .label
        
        cell.backgroundColor = .clear
        
        // 선택 배경 설정
        let selectedBg = UIView()
        selectedBg.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.5)
        cell.selectedBackgroundView = selectedBg
        
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
                    // 판매자/도매업자: 관리자 상품리스트 (SwiftUI로 변경)
                    var rootView = ProductListSwiftUIView()
                    rootView.onSelectProduct = { item in
                        AppCoordinator.shared?.showProductDetail(
                            pid: Int64(item.productId ?? "") ?? 0,
                            userId: item.userId ?? "",
                            title: item.title ?? ""
                        )
                    }
                    rootView.onAddProduct = {
                        let vc = MakeAdMainViewController(service: AppServiceProvider.shared)
                        nav.pushViewController(vc, animated: true)
                    }
                    rootView.onShowNotifications = {
                        AppCoordinator.shared?.showNotificationList()
                    }
                    
                    let vc = UIHostingController(rootView: rootView)
                    vc.navigationItem.title = "내 등록 매물"
                    vc.addLeftMenuButton() // ✅ 햄버거 메뉴 버튼 추가
                    nav.pushViewController(vc, animated: true)
                } else {
                    // 나머지 (ROLE_BUYER 등): 메인 탭바 컨트롤러 -> SwiftUI로 변경
                    var rootView = MainTabView()
                    rootView.onSelectProduct = { item in
                        AppCoordinator.shared?.showProductDetail(
                            pid: Int64(item.productId ?? "") ?? 0,
                            userId: item.userId ?? "",
                            title: item.title ?? ""
                        )
                    }
                    rootView.onShowNotifications = {
                        AppCoordinator.shared?.showNotificationList()
                    }
                    let vc = UIHostingController(rootView: rootView)
                    vc.navigationItem.title = "상품리스트"
                    vc.addLeftMenuButton() // ✅ 햄버거 메뉴 버튼 추가
                    nav.pushViewController(vc, animated: true)
                }
            case .settings:
                var rootView = SettingsView()
                rootView.onShowNotifications = {
                    AppCoordinator.shared?.showNotificationList()
                }
                let vc = UIHostingController(rootView: rootView)
                vc.navigationItem.title = selected.title
                vc.navigationItem.hidesBackButton = true // ✅ 뒤로가기 숨김
                vc.addLeftMenuButton() // ✅ 햄버거 메뉴 추가
                nav.pushViewController(vc, animated: true)
                
            case .orderManagement:
                var rootView = OrderManagementView()
                rootView.onToggleMenu = {
                    guard let menu = SideMenuManager.default.leftMenuNavigationController else { return }
                    nav.present(menu, animated: true)
                }
                rootView.onShowNotifications = {
                    AppCoordinator.shared?.showNotificationList()
                }
                let vc = UIHostingController(rootView: rootView)
                vc.navigationItem.title = "주문관리"
                vc.navigationItem.hidesBackButton = true // ✅ 뒤로가기 숨김 (햄버거만 노출)
                nav.pushViewController(vc, animated: true)
                
            case .notice:
                print("*****notice******")
                self.openWebMenu("notice", loginNo: loginNo, nav: nav)
                
            case .inquiry:
                print("*****inquiry******")
                self.openWebMenu("discuss", loginNo: loginNo, nav: nav)
                
            case .policy:
                print("*****inquiry******")
                self.openWebMenu("forum", loginNo: loginNo, nav: nav)
            }
        }
    }
    
    func openWebMenu(_ type: String, loginNo: String, nav: UINavigationController) {
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
        
        var rootView = WebSwiftUIView(urlString: urlString, title: title)
        rootView.onShowNotifications = {
            AppCoordinator.shared?.showNotificationList()
        }
        rootView.onToggleMenu = {
            guard let menu = SideMenuManager.default.leftMenuNavigationController else { return }
            nav.present(menu, animated: true)
        }
        let vc = UIHostingController(rootView: rootView)
        nav.pushViewController(vc, animated: true)
    }
}
