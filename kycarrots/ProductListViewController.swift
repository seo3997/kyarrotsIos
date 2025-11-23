import UIKit

// 판매 상태 정의 (네 프로젝트 코드값 반영)
enum SaleStatus: Int, CaseIterable {
    case rejected = 98      // 승인반려(반려)
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
}

// 간단한 상품 모델 (필요에 맞춰 확장)
struct Product {
    let id: String
    let name: String
    let price: Int
    let status: SaleStatus
}

final class ProductListViewController: UIViewController {
    private let floatingButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.systemBlue
        button.tintColor = .white
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.layer.cornerRadius = 28  // 버튼 크기 56 → 안드로이드 FAB 동일
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowRadius = 4
        return button
    }()
    
    // 상단 탭(세그먼트)
    private lazy var segmented: UISegmentedControl = {
        let seg = UISegmentedControl(items: SaleStatus.allCases.map { $0.title })
        seg.selectedSegmentIndex = 1 // 기본: 판매중
        seg.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        return seg
    }()

    // 목록 테이블
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var refresh = UIRefreshControl()

    // 전체 상품 (보통은 API 응답으로 채움)
    private var allProducts: [Product] = []

    // 현재 선택된 상태
    private var currentStatus: SaleStatus {
        SaleStatus.allCases[segmented.selectedSegmentIndex]
    }

    // 현재 상태의 필터링 결과
    private var filtered: [Product] {
        allProducts.filter { $0.status == currentStatus }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "상품리스트"
        view.backgroundColor = .systemBackground
        print("VC type =", type(of: self))  //DashboardViewControllerTableViewController 나와야 함
        print("storyboard =", storyboard?.description as Any)

        setupLayout()
        setupFloatingButton()
        setupTable()
        fetchProducts() // 최초 로드(데모 데이터)
        // 기본 탭을 "판매중"으로 하고 싶으면 위 selectedSegmentIndex = 1 유지
    }

    private func setupLayout() {
        // 상단 탭
        view.addSubview(segmented)
        segmented.translatesAutoresizingMaskIntoConstraints = false

        // 테이블
        view.addSubview(tableView)
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
        //tableView.rowHeight = 60

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        
        tableView.register(
              UINib(nibName: "ProductTableViewCell", bundle: nil),
              forCellReuseIdentifier: ProductTableViewCell.reuseIdentifier
          )
        refresh.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        tableView.refreshControl = refresh
    }

    // 탭 변경 시 리스트 갱신
    @objc private func segChanged() {
        tableView.reloadData()
        scrollToTopIfNeeded()
    }

    @objc private func onRefresh() {
        // TODO: 실제 API 재호출
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.refresh.endRefreshing()
            self.tableView.reloadData()
        }
    }

    private func scrollToTopIfNeeded() {
        guard tableView.numberOfRows(inSection: 0) > 0 else { return }
        tableView.setContentOffset(.zero, animated: true)
    }

    // MARK: - 데모용 데이터 로딩 (실제에선 API 연동)
    private func fetchProducts() {
        // 예시 데이터(상태 골고루)
        allProducts = [
            .init(id: "P001", name: "꿀사과 5kg",   price: 25000, status: .onSale),
            .init(id: "P002", name: "청포도 2kg",   price: 18000, status: .reserved),
            .init(id: "P003", name: "한우 1+ 등심", price: 98000, status: .soldOut),
            .init(id: "P004", name: "유기농 상추",   price: 3500,  status: .rejected),
            .init(id: "P005", name: "방울토마토",    price: 7900,  status: .onSale),
            .init(id: "P006", name: "감자 10kg",     price: 19000, status: .reserved),
            .init(id: "P007", name: "고구마 5kg",    price: 17000, status: .onSale),
            .init(id: "P008", name: "표고버섯 1kg",  price: 22000, status: .rejected),
        ]
        tableView.reloadData()
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
    
    @objc private func floatingButtonTapped() {
        print("Floating button tapped!")
        // 여기에 상품등록 화면 이동 넣으면 됨
    }
}

// MARK: - UITableViewDataSource
extension ProductListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = filtered.count
        if count == 0 {
            // 빈 상태 표시 (간단)
            tableView.setEmptyMessage("해당 상태의 상품이 없습니다.")
        } else {
            tableView.restore()
        }
        return count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = filtered[indexPath.row]
        /*
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = "₩\(item.price.formatted()) • \(item.status.title)"
        */
        let cell = tableView.dequeueReusableCell(
                withIdentifier: ProductTableViewCell.reuseIdentifier,
                for: indexPath
            ) as! ProductTableViewCell

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

        let item = filtered[indexPath.row]
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        vc.title = item.name

        // TODO: 실제 상세 VC로 교체
        // let vc = ProductDetailViewController(productId: item.id)

        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - 테이블 Empty State 유틸
private extension UITableView {
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
