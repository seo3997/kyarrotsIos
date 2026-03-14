import UIKit
import SideMenu

final class MainViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Carrot Market"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal"),
            style: .plain,
            target: self,
            action: #selector(didTapHamburger)
        )

        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupProfileButton()
    }
    
    private func setupProfileButton() {
        let avatarView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 20
        avatarView.clipsToBounds = true
        avatarView.backgroundColor = .systemGray6
        avatarView.tintColor = .systemGray2
        
        if let localImage = ProfileImageUtil.getLocalProfileImage() {
            avatarView.image = localImage
        } else {
            avatarView.image = UIImage(systemName: "person.fill")
        }
        
        let container = UIView(frame: avatarView.frame)
        container.addSubview(avatarView)
        
        // 클릭 시 특별한 동작이 필요 없다면 그냥 커스텀 뷰로 설정
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: container)
    }

    @objc private func didTapHamburger() {
        if let menu = SideMenuManager.default.leftMenuNavigationController {
            present(menu, animated: true, completion: nil)
        }
    }
}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 20 }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = "Item \(indexPath.row + 1)"
        cell.detailTextLabel?.text = "Demo content"
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        vc.title = "Detail \(indexPath.row + 1)"
        navigationController?.pushViewController(vc, animated: true)
    }
}
