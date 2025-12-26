//
//  DashboardViewController.swift
//  kycarrots
//
//  Created by soohyun on 11/3/25.
//

import UIKit

// 안드로이드에서 RecentProductAdapter가 화면에 보여주는 문자열만 따로 빼놓은 뷰모델 역할
// (title: "배추 500kg …", subInfo: "지역 / 희망 발송일", statusName: "처리중" 등)
struct RecentProductViewModel {
    let title: String
    let subInfo: String
    let statusName: String?
    
    // 상세 이동에 필요한 값들 (안드로이드에서는 imageUrl, productId, userId 를 넘김)
    let imageUrl: String?
    let productId: String
    let userId: String
}

class DashboardViewController: UITableViewController {
    
    // MARK: - IBOutlets (스토리보드에서 연결 필요)
    
    /// 전체 헤더 카드(통계 영역)를 담고 있는 뷰
    @IBOutlet weak var headerCardView: UIView!
    
    /// 헤더 안쪽의 카드 뷰 (모서리 둥글게 + 그림자)
    @IBOutlet weak var cardView: UIView!
    
    /// "총 등록 매물: 0건" 표시 레이블 (안드로이드 tv_total_products 대응)
    @IBOutlet weak var lblTotalProducts: UILabel!
    
    /// "승인반려: / 처리중: / 완료:" 표시 레이블 (안드로이드 tv_stats 대응)
    @IBOutlet weak var lblStats: UILabel!
    
    /// "더보기" 텍스트(혹은 버튼) – 안드로이드 tv_more 대응
    @IBOutlet weak var lblMore: UIButton!
    
    /// "상품 등록" 버튼 – 안드로이드 btn_add_product 대응
    @IBOutlet weak var btnAddProduct: UIButton!
    
    /// "승인대기/처리 화면"으로 가는 버튼 – 안드로이드 btn_approval_product 대응
    @IBOutlet weak var btnApprovalProduct: UIButton!

    /// 새매물 등록하기 버튼 하나만 노출시 spaceView 를 노출 시켜 1/2 버튼으로 보이게 한ㄷ
    @IBOutlet weak var spaceView: UIView!

    private var noDataCardView: UIView!
    private var loadingView: UIView!
    
    // MARK: - Properties
    
    private var items: [RecentProductViewModel] = []
    
    /// 안드로이드 AppService와 동일 역할의 서비스 (이미 프로젝트에 구현해둔 것 사용)
    private let appService = AppServiceProvider.shared
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "대시보드"
        addLeftMenuButton()
        
        // 햄버거 메뉴 버튼 (SideMenu)
        /*
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal"),
            style: .plain,
            target: self,
            action: #selector(didTapHamburger)
        )
        */
        
        print("VC type =", type(of: self))
        print("storyboard =", storyboard?.description as Any)
        print("headerCardView =", headerCardView as Any)
        print("UserId =", LoginInfoUtil.getUserId())
        
        setupHeaderCard()
        setupTableView()
        setupButtons()
        setupOverlayViews()
        
        // 초기 로딩
        initDashboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 안드로이드 onResume에서 initDashboard() + 알림 뱃지 갱신하듯이
        initDashboard()
        // TODO: iOS 쪽 NotificationBadge 구현되면 여기서 갱신
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationBadgeManager.shared.hide()
    }
    
    @objc private func tapNotifications() {
        let vc = NotificationListViewController()
        navigationController?.pushViewController(vc, animated: true)
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
    // MARK: - Setup UI
    
    private func setupHeaderCard() {
        guard let header = headerCardView else { return }
        
        // tableHeaderView로 올리기
        header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 200)
        tableView.tableHeaderView = header
        
        // 카드 스타일
        cardView.layer.cornerRadius = 12
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.systemGray5.cgColor
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.12
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        cardView.layer.masksToBounds = false
        
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }
    
    private func setupTableView() {
        // 이미 스토리보드에서 RecentProductCell 프로토타입 셀을 만들고
        // reuse identifier 를 RecentProductCell.reuseID 로 맞춰둔 상태라고 가정
        // 만약 NIB를 쓰면 register 필요
        // tableView.register(RecentProductCell.self, forCellReuseIdentifier: RecentProductCell.reuseID)
    }
    
    private func setupButtons() {
        // "더보기" 탭 → 안드로이드에서 MainActivity 로 이동하던 부분 대응
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(didTapMore))
        lblMore.isUserInteractionEnabled = true
        lblMore.addGestureRecognizer(moreTap)
        
        // 상품 등록 버튼
        btnAddProduct.addTarget(self, action: #selector(didTapAddProduct), for: .touchUpInside)
        
        // 승인/처리 화면 버튼
        btnApprovalProduct.addTarget(self, action: #selector(didTapApprovalProduct), for: .touchUpInside)
        
        // 권한/시스템 타입에 따른 show/hide
        if LoginInfoUtil.getMemberCode() == Constants.ROLE_SELL {
            // 판매자
            btnAddProduct.isHidden = false
            btnApprovalProduct.isHidden = true
        } else if Constants.SYSTEM_TYPE == 2 {
            // 시스템 타입 2 – 센터(도매상) 승인 화면
            btnAddProduct.isHidden = true
            btnApprovalProduct.isHidden = true   // 필요 시 false 로 조정
            // 안드로이드에서는 btnApprovalProduct 를 VISIBLE 로 두지만,
            // 실제 iOS 화면 플로우에 맞게 조정
        } else {
            // 기본값
            btnAddProduct.isHidden = false
            btnApprovalProduct.isHidden = true
        }
    }
    
    // MARK: - Actions
    /*
    @objc private func didTapHamburger() {
        if let menu = SideMenuManager.default.leftMenuNavigationController {
            present(menu, animated: true, completion: nil)
        }
    }
    */
    
    @objc private func didTapMore() {
        // 안드로이드: startActivity(Intent(this, MainActivity::class.java))
        // iOS: 상품 목록 탭/VC로 이동
        // TODO: 실제 스토리보드 ID나 화면 구조에 맞게 수정
        /*
        if let storyboard = storyboard,
           let vc = storyboard.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
        */
        print("더보기 탭 → 상품 목록 화면으로 이동 TODO")
    }
    
    @objc private func didTapAddProduct() {
        // 안드로이드와 동일하게 SYSTEM_TYPE 에 따라 분기
        if Constants.SYSTEM_TYPE == 1 {
            // 바로 광고(상품) 등록 화면으로
            moveToMakeAD()
        } else if Constants.SYSTEM_TYPE == 2 {
            // 기본 중간센터 확인 후 상품등록
            handleAddProductClick()
        }
    }
    
    @objc private func didTapApprovalProduct() {
        // 안드로이드: 승인/처리 화면(MainActivity)로 이동
        // TODO: 실제 iOS 승인/처리 화면으로 이동하도록 구현
        print("승인/처리 화면 이동 TODO")
    }
    
    // MARK: - Dashboard Logic (안드로이드 포팅)
    
    private func initDashboard() {
        let token = TokenUtil.getToken()
        loadDashboardStats(token: token)
        loadRecentProducts(token: token)
    }
    
    private func loadDashboardStats(token: String) {
        showProgress(true)
        
        Task {
            do {
                // 안드로이드: appService.getProductDashboard(token) : Map<String, Int>
                let stats = try await appService.getProductDashboard(token: token)
                
                DispatchQueue.main.async {
                    self.updateDashboardUI(stats: stats)
                }
            } catch {
                print("loadDashboardStats error:", error)
            }
        }
    }
    
    private func updateDashboardUI(stats: [String: Int]) {
        // 안드로이드의 문구 그대로 맞춰줌
        let total = stats["totalCount"] ?? 0
        let request = stats["reguestCount"] ?? 0   // 오타지만 서버/안드로이드와 동일 키 사용
        let processing = stats["processingCount"] ?? 0
        let completed = stats["completedCount"] ?? 0
        
        lblTotalProducts.text = "총 등록 매물: \(total)건"
        lblStats.text = "승인반려:\(request)건 / 처리 중: \(processing)건 / 완료: \(completed)건"
    }
    
    private func loadRecentProducts(token: String) {
        showProgress(true)
        
        Task {
            do {
                // 안드로이드: appService.getRecentProducts(token): List<ProductVo>
                let recentList = try await appService.getRecentProducts(token: token)
                
                let viewModels: [RecentProductViewModel] = recentList.map { product in
                    // 수량 포맷: "%,d" 와 동일하게 천단위 콤마
                    let qtyInt = Int(product.quantity ?? "") ?? 0
                    let formattedQty = NumberFormatter.localizedString(from: NSNumber(value: qtyInt), number: .decimal)
                    
                    let title = "\(product.title ?? "") \(formattedQty) \(product.unitCodeNm ?? "-")"
                    let subInfo = "\(product.areaMidNm ?? "") \(product.areaSclsNm ?? "") / \(product.desiredShippingDate ?? "")"
                    
                    return RecentProductViewModel(
                        title: title,
                        subInfo: subInfo,
                        statusName: product.saleStatusNm,
                        imageUrl: product.imageUrl,
                        productId: product.productId ?? "",
                        userId: product.userId ?? ""
                    )
                }
                
                DispatchQueue.main.async {
                    self.items = viewModels
                    self.tableView.reloadData()
                    
                    let hasData = !viewModels.isEmpty
                    self.noDataCardView.isHidden = hasData
                    self.tableView.isHidden = !hasData
                    self.showProgress(false)
                }
            } catch {
                print("loadRecentProducts error:", error)
                DispatchQueue.main.async {
                    self.items = []
                    self.tableView.reloadData()
                    self.noDataCardView.isHidden = false
                    self.tableView.isHidden = true
                    self.showProgress(false)
                }
            }
        }
    }
    
    // 안드로이드 handleAddProductClick() 포팅
    private func handleAddProductClick() {
        let userId = LoginInfoUtil.getUserId()
        showProgress(true)
        
        Task {
            do {
                // 1) 기본 중간센터 조회
                let defaultWholesalerNo = try await appService.getDefaultWholesaler(userId: userId)
                if defaultWholesalerNo != nil {
                    // 이미 지정됨 → 바로 이동
                    DispatchQueue.main.async {
                        self.showProgress(false)
                        self.moveToMakeAD()
                    }
                    return
                }
                
                // 2) 기본센터 없음 → 도매상(중간센터) 목록 불러오기
                let wholesalers = try await appService.getWholesalers(memberCode: Constants.ROLE_PROJ)
                
                if wholesalers.isEmpty {
                    DispatchQueue.main.async {
                        self.showProgress(false)
                        self.showAlert(message: "선택 가능한 중간센터가 없습니다.")
                    }
                    return
                }
                
                // 3) 센터 선택 액션시트
                DispatchQueue.main.async {
                    self.showProgress(false)
                    self.presentCenterPicker(wholesalers: wholesalers, userId: userId)
                }
                
            } catch {
                print("handleAddProductClick error:", error)
                DispatchQueue.main.async {
                    self.showProgress(false)
                    self.showAlert(message: "처리 중 오류가 발생했습니다.")
                }
            }
        }
    }
    
    private func presentCenterPicker(wholesalers: [OpUserVO], userId: String) {
        let alert = UIAlertController(title: "센터/도매상 선택", message: nil, preferredStyle: .actionSheet)
        
        for w in wholesalers {
            let name = "\(w.userNm ?? "")(\(w.userNo ?? "0"))"
            alert.addAction(UIAlertAction(title: name, style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.setDefaultWholesalerAndMove(userId: userId, wholesalerNo: w.userNo!)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        
        // iPad 대응 (actionSheet)
        if let popover = alert.popoverPresentationController {
            popover.sourceView = btnAddProduct
            popover.sourceRect = btnAddProduct.bounds
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    private func setDefaultWholesalerAndMove(userId: String, wholesalerNo: String?) {
        guard let wholesalerNo = wholesalerNo else { return }
        
        showProgress(true)
        Task {
            do {
                let ok = try await appService.setDefaultWholesaler(userId: userId, wholesalerNo: wholesalerNo)
                DispatchQueue.main.async {
                    self.showProgress(false)
                    if ok {
                        self.showAlert(message: "기본 중간센터 지정 완료")
                        self.moveToMakeAD()
                    } else {
                        self.showAlert(message: "센터 지정 실패")
                    }
                }
            } catch {
                print("setDefaultWholesaler error:", error)
                DispatchQueue.main.async {
                    self.showProgress(false)
                    self.showAlert(message: "센터 지정 중 오류가 발생했습니다.")
                }
            }
        }
    }
    
    private func moveToMakeAD() {
        // 안드로이드: MakeADMainActivity 로 이동 + putExtra(STR_PUT_AD_IDX, "")
        // iOS: 광고(상품) 등록 첫 화면으로 push
        // TODO: 실제 광고등록 VC 이름/스토리보드 ID에 맞게 수정
        /*
        if let storyboard = storyboard,
           let vc = storyboard.instantiateViewController(withIdentifier: "MakeAdMainViewController") as? MakeAdMainViewController {
            // 필요하면 vc.adIdx = "" 세팅
            navigationController?.pushViewController(vc, animated: true)
        }
        */
        print("상품등록 화면으로 이동 TODO")
    }
    
    // MARK: - Loading / Alert
    
    private func showProgress(_ show: Bool) {
        loadingView?.isHidden = !show
        if show {
            view.bringSubviewToFront(loadingView)
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func setupOverlayViews() {
        guard let containerView = navigationController?.view else { return }

        // 1) 로딩 오버레이
        loadingView = UIView(frame: containerView.bounds)
        loadingView.backgroundColor = UIColor(white: 0, alpha: 0.25)
        loadingView.isHidden = true

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.center = loadingView.center
        indicator.startAnimating()
        loadingView.addSubview(indicator)

        containerView.addSubview(loadingView)

        // 2) noData 카드
        let width = containerView.bounds.width - 40
        noDataCardView = UIView(frame: CGRect(x: 20, y: 140, width: width, height: 120))
        noDataCardView.backgroundColor = .systemBackground
        noDataCardView.layer.cornerRadius = 12
        noDataCardView.layer.shadowColor = UIColor.black.cgColor
        noDataCardView.layer.shadowOpacity = 0.12
        noDataCardView.layer.shadowRadius = 4
        noDataCardView.isHidden = true

        let label = UILabel(frame: noDataCardView.bounds.insetBy(dx: 8, dy: 8))
        label.text = "최근 등록된 매물이 없습니다."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .medium)
        noDataCardView.addSubview(label)

        containerView.addSubview(noDataCardView)
    }

    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: RecentProductCell.reuseID,
            for: indexPath
        ) as! RecentProductCell
        
        let item = items[indexPath.row]
        cell.configure(title: item.title, subInfo: item.subInfo, statusText: item.statusName)
        cell.onTapButton = { [weak self] in
            guard let self = self else { return }
            print("처리중 버튼 탭: \(item.title)")
            // TODO: 상태 변경/상세화면 이동
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vm = items[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 안드로이드: AdDetailActivity 로 이동 + imageUrl, productId, userId 전달
        // iOS: AdDetailViewController 로 이동한다고 가정
        // TODO: 실제 클래스/스토리보드 ID에 맞게 수정
        /*
        if let storyboard = storyboard,
           let vc = storyboard.instantiateViewController(withIdentifier: "AdDetailViewController") as? AdDetailViewController {
            vc.imageUrl = vm.imageUrl
            vc.productId = vm.productId
            vc.userId = vm.userId
            navigationController?.pushViewController(vc, animated: true)
        }
        */
        print("최근 매물 선택 → 상세 화면 이동 TODO, productId=\(vm.productId)")
    }
}
