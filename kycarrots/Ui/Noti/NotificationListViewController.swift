//
//  NotificationListViewController.swift
//  kycarrots
//
//  Created by soo on 12/26/25.
//


import UIKit

final class NotificationListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    private let repo: PushRepository
    private let userIdProvider: () -> String?

    private var items: [PushNotification] = []

    init(
        repo: PushRepository = CoreDataPushRepository(),
        userIdProvider: @escaping () -> String? = { UserDefaults.standard.string(forKey: "LogIn_ID") }
    ) {
        self.repo = repo
        self.userIdProvider = userIdProvider
        super.init(nibName: nil, bundle: nil)
        self.title = "알림 리스트"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "알림이 없습니다."
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.isHidden = true

        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
        ])

        // 우측 상단: 전체 읽음(원하면)
        /*
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "전체읽음",
            style: .plain,
            target: self,
            action: #selector(onTapMarkAllRead)
        )
         */
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Android처럼 “진입 시 전체 읽음 처리 + 로드”
        markAllReadAndReload()
    }

    @objc private func onTapMarkAllRead() {
        markAllReadAndReload()
    }

    private func markAllReadAndReload() {
        guard let userId = userIdProvider(), !userId.isEmpty else { return }

        do {
            try repo.markAllRead(userId: userId)
            try loadList(userId: userId)
        } catch {
            print("Notification load failed: \(error)")
        }
    }

    private func loadList(userId: String) throws {
        let rows = try repo.list(userId: userId, onlyUnread: false, limit: 100, offset: 0)
        self.items = rows
        tableView.reloadData()

        let hasItems = !rows.isEmpty
        emptyLabel.isHidden = hasItems
        tableView.isHidden = !hasItems
    }

    private func handleClick(_ item: PushNotification) {
        // 개별 읽음 처리(Android 동일)
        do { try repo.markRead(id: item.id) } catch { print(error) }

        // 라우팅 (Android 로직과 동일하게 분기만 구성) :contentReference[oaicite:5]{index=5}
        switch item.type {
        case NotifType.CHAT:
            // roomId: "productId_buyerId_sellerId" 형태라면 동일하게 split 가능
            // TODO: ChatViewController로 push
            print("Open CHAT roomId=\(item.roomId ?? "")")

        case NotifType.PRODUCT_REGISTERED, NotifType.PRODUCT_APPROVED, NotifType.PRODUCT_REJECTED, "PRODUCT":
            // TODO: ProductDetailViewController로 push (productId, sellerId 전달)
            print("Open PRODUCT productId=\(item.productId ?? 0), sellerId=\(item.sellerId ?? "")")

        default:
            if let deeplink = item.deeplink, let url = URL(string: deeplink) {
                UIApplication.shared.open(url)
            }
        }
    }

    private func deleteOne(_ item: PushNotification) {
        do {
            try repo.delete(id: item.id)
            guard let userId = userIdProvider(), !userId.isEmpty else { return }
            try loadList(userId: userId)
        } catch {
            print("Delete failed: \(error)")
        }
    }
}

// MARK: - UITableView
extension NotificationListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.reuseId, for: indexPath) as! NotificationCell
        cell.bind(item)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        handleClick(item)
    }

    // iOS 스타일 삭제(스와이프)
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let item = items[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, done in
            self?.deleteOne(item)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
