import UIKit

// 안드로이드 코드의 상태코드 기준으로 UI 라벨만 담당
// (실제 API에는 saleStatus "1","10","99","98" 같은 코드가 넘어감)
enum SaleStatus: Int, CaseIterable {
    case rejected = 98      // 승인반려(또는 반려)
    case onSale  = 1        // 판매중
    case reserved = 10      // 예약중
    case soldOut = 99       // 판매완료

    var title: String {
        switch self {
        case .rejected: return "승인반려"
        case .onSale:   return "판매중"
        case .reserved: return "예약중"
        case .soldOut:  return "판매완료"
        }
    }

    /// 서버에 넘길 saleStatus 코드
    var apiCode: String {
        switch self {
        case .rejected: return "0"   // 서버에서 반려가 98이면 "98"로 바꾸면 됨
        case .onSale:   return "1"
        case .reserved: return "10"
        case .soldOut:  return "99"
        }
    }
}

final class ProductListViewController: UIViewController {

    // MARK: - Dependencies
    private let appService = AppServiceProvider.shared   // 안드로이드 AppService와 동일 역할

    // MARK: - UI
    private lazy var segmented: UISegmentedControl = {
        let seg = UISegmentedControl(items: SaleStatus.allCases.map { $0.title })
        seg.selectedSegmentIndex = 0   // 기본 탭(현재는 첫 탭)
        seg.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        return seg
    }()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var refresh = UIRefreshControl()
 
    private let floatingButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.systemBlue
        button.tintColor = .white
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowRadius = 4
        return button
    }()

    // ✅ 전체 화면 로딩 오버레이
    private var loadingOverlay: UIView?
    private let overlaySpinner = UIActivityIndicatorView(style: .large)

    // ✅ 오른쪽 상단 알림 버튼 + 뱃지
    private var notifButton: UIButton!

    // MARK: - Paging & Data
    private var items: [AdItem] = []
    private var pageNo: Int = 1
    private var isLoading: Bool = false
    private var isLastPage: Bool = false

    private var currentStatus: SaleStatus {
        SaleStatus.allCases[segmented.selectedSegmentIndex]
    }

    private var currentSaleStatusCode: String {
        currentStatus.apiCode
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addLeftMenuButton()
        title = "내 등록 매물"
        view.backgroundColor = .systemBackground

        setupLayout()
        setupTable()
        setupFloatingButton()

        // ✅ 오른쪽 상단: 알림 아이콘 + 뱃지

        // 첫 로드 (전체 로딩)
        fetchProducts(isRefresh: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationBadgeManager.shared.hide()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNotificationBarButton()
        refreshNotificationBadge()
    }

    private func setupNotificationBarButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "bell"),
                style: .plain,
                target: self,
                action: #selector(tapNotifications)
            )

        if let navBar = navigationController?.navigationBar {
            NotificationBadgeManager.shared.installIfNeeded(on: navBar)
        }
    }
    private func refreshNotificationBadge() {
        let userId = LoginInfoUtil.getUserId()

        Task {
            let count = await NotificationBadgeHelper.fetchUnreadCount(userId: userId)
            await MainActor.run {
                NotificationBadgeManager.shared.updateCount(count)
            }
        }
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(segmented)
        view.addSubview(tableView)

        segmented.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            tableView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100

        tableView.register(
            UINib(nibName: "ProductTableViewCell", bundle: nil),
            forCellReuseIdentifier: ProductTableViewCell.reuseIdentifier
        )

        refresh.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        tableView.refreshControl = refresh
    }

    private func setupFloatingButton() {
        view.addSubview(floatingButton)

        NSLayoutConstraint.activate([
            floatingButton.widthAnchor.constraint(equalToConstant: 56),
            floatingButton.heightAnchor.constraint(equalToConstant: 56),
            floatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            floatingButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40)
        ])

        floatingButton.addTarget(self, action: #selector(floatingButtonTapped), for: .touchUpInside)
    }

    // MARK: - ✅ Fullscreen Loading

    private func showFullScreenLoading() {
        if loadingOverlay != nil { return }

        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        overlay.isUserInteractionEnabled = true // 터치 막기

        overlaySpinner.translatesAutoresizingMaskIntoConstraints = false
        overlaySpinner.startAnimating()

        overlay.addSubview(overlaySpinner)
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            overlaySpinner.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            overlaySpinner.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])

        loadingOverlay = overlay
    }

    private func hideFullScreenLoading() {
        overlaySpinner.stopAnimating()
        loadingOverlay?.removeFromSuperview()
        loadingOverlay = nil
    }

    // MARK: - Actions

    @objc private func segChanged() {
        fetchProducts(isRefresh: true) // 탭 변경 시 전체 로딩 + 처음부터
    }

    @objc private func onRefresh() {
        fetchProducts(isRefresh: true) // pull to refresh 시 전체 로딩 + 처음부터
    }

    @objc private func floatingButtonTapped() {
        print("Floating button tapped - 상품 등록 화면으로 이동 예정")
        // TODO: 안드로이드 MakeADMainActivity 대응 iOS 화면으로 push/present
    }

    @objc private func tapNotifications() {
        // TODO: 알림/메시지 리스트 화면으로 이동
        let vc = NotificationListViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - API 연동 (안드로이드 AdListFragment.fetchAdvertiseList 대응)

    private func fetchProducts(isRefresh: Bool = false) {
        if isLoading { return }
        if !isRefresh && isLastPage { return }

        isLoading = true

        // ✅ 리프레시/첫로드/탭변경이면 전체 로딩 오버레이
        if isRefresh {
            showFullScreenLoading()
        }

        if isRefresh {
            pageNo = 1
            isLastPage = false
            items.removeAll()
            tableView.reloadData()
            tableView.setContentOffset(.zero, animated: false)
        }

        let token = TokenUtil.getToken()
        let memberCode = LoginInfoUtil.getMemberCode()

        guard !token.isEmpty else {
            print("토큰 없음 → 로그인 필요")
            isLoading = false
            hideFullScreenLoading()
            refresh.endRefreshing()
            return
        }

        let req = AdListRequest(
            token: token,
            adCode: 1,
            pageno: pageNo,
            saleStatus: currentSaleStatusCode,
            memberCode: memberCode
        )

        Task {
            do {
                let ads = try await appService.getAdvertiseList(req: req)
                await MainActor.run { [weak self] in
                    guard let self else { return }

                    if ads.isEmpty {
                        self.isLastPage = true
                        if self.pageNo == 1 {
                            self.tableView.setEmptyMessage("해당 상태의 상품이 없습니다.")
                        } else {
                            self.tableView.restore()
                        }
                    } else {
                        self.tableView.restore()
                        self.items.append(contentsOf: ads)
                        self.pageNo += 1
                    }
                    self.tableView.reloadData()
                }
            } catch {
                print("getAdvertiseList 실패: \(error)")
            }

            await MainActor.run { [weak self] in
                guard let self else { return }
                self.isLoading = false
                self.refresh.endRefreshing()
                if isRefresh { self.hideFullScreenLoading() } // ✅ 전체 로딩 OFF
            }
        }
    }
    
}

// MARK: - UITableViewDataSource

extension ProductListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        let count = items.count
        if count == 0 {
            tableView.setEmptyMessage("해당 상태의 상품이 없습니다.")
        } else {
            tableView.restore()
        }
        return count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: ProductTableViewCell.reuseIdentifier,
            for: indexPath
        ) as! ProductTableViewCell

        let item = items[indexPath.row]
        cell.configure(with: item)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ProductListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = items[indexPath.row]

        // 안드로이드 AdDetailActivity 대응 상세화면으로 이동
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ProductDetailVC") as! ProductDetailViewController
        vc.productId = Int64(item.productId ?? "") ?? 0
        vc.productUserId = item.userId ?? ""
        vc.productTitle = item.title ?? ""
        navigationController?.pushViewController(vc, animated: true)
    }

    // 페이징: 마지막 근처 셀 표시될 때 다음 페이지 로드
    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        let threshold = items.count - 5
        if indexPath.row >= threshold {
            fetchProducts()
        }
    }
}

// MARK: - 테이블 Empty State 유틸 (기존 코드 재사용)

extension UITableView {
    func setEmptyMessage(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView(frame: bounds)
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
        ])

        backgroundView = container
    }

    func restore() {
        backgroundView = nil
    }
}
