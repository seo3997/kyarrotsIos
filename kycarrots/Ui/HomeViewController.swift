import UIKit

final class HomeViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingOverlay: UIView! // 전체를 덮는 뷰 추가
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    // 필터용 버튼 및 스위치
    @IBOutlet weak var categoryBtn: UIButton!
    @IBOutlet weak var subCategoryBtn: UIButton!  // 추가: 세부 카테고리
    @IBOutlet weak var areaBtn: UIButton!
    @IBOutlet weak var districtBtn: UIButton!     // 추가: 구/군 지역
    @IBOutlet weak var saleSwitch: UISwitch!
    
    // 가격 필터 관련 추가
    @IBOutlet weak var priceFilterSwitch: UISwitch!
    @IBOutlet weak var priceSlider: UISlider!
    @IBOutlet weak var priceRangeLabel: UILabel!

    // MARK: - Properties
    private let appService = AppServiceProvider.shared
    private var items: [AdItem] = []
    
    private var currentPage = 1
    private var isLoading = false
    private var isEndReached = false
    
    // 필터 데이터 전송용 (안드로이드 selectedCategoryMid 등과 매칭)
    private var selectedCategoryMid = "ALL"
    private var selectedCategoryScls = "ALL" // ★ 이 줄을 추가하세요!
    private var selectedAreaMid = "ALL"
    private var selectedAreaScls = "ALL"     // ★ 이 줄도 함께 추가해두면 좋습니다!
    private var maxPrice: Int = 9990000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "상품 리스트"
        // 처음에는 로딩 뷰를 숨겨둡니다.
        loadingOverlay.isHidden = true
        loadingIndicator.hidesWhenStopped = true
        
        setupTableView()
        setupPriceFilterUI() // 가격 UI 초기화
        loadInitialFilterData() // 카테고리/지역 목록 가져오기
        loadInitialData()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ✅ 부모인 탭바 컨트롤러의 타이틀을 변경해야 상단 바에 반영됩니다.
        self.tabBarController?.title = "상품 리스트"
    }
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        let nib = UINib(nibName: "ProductTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: ProductTableViewCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 110
    }

    // MARK: - Filter Logic (안드로이드 loadCategories/loadCities 대응)

    private func loadInitialFilterData() {
        Task {
            // 1. 카테고리(대분류) 로드
            let cats = await appService.getCodeList(groupId: "R010610")
            setupMenu(for: categoryBtn, items: cats) { selected in
                self.selectedCategoryMid = selected.strIdx ?? "ALL"
                // 안드로이드 로직: 대분류 선택 시 세부 카테고리(중분류) 로드
                self.loadSubCategories(categoryMid: self.selectedCategoryMid)
            }

            // 2. 도시(대지역) 로드
            let cityList = await appService.getCodeList(groupId: "R010070")
            setupMenu(for: areaBtn, items: cityList) { selected in
                self.selectedAreaMid = selected.strIdx ?? "ALL"
                // 안드로이드 로직: 도시 선택 시 구/군(District) 로드
                self.loadDistricts(cityCode: self.selectedAreaMid)
            }
        }
    }
    
    private func loadSubCategories(categoryMid: String) {
        Task {
            let subCats = await appService.getSCodeList(groupId: "R010610", mcode: categoryMid)
            await MainActor.run {
                setupMenu(for: subCategoryBtn, items: subCats) { selected in
                    // 안드로이드의 selectedCategoryScls = item.strIdx 로직
                    self.selectedCategoryScls = selected.strIdx ?? "ALL"
                }
            }
        }
    }
  
    private func loadDistricts(cityCode: String) {
        Task {
            let districts = await appService.getSCodeList(groupId: "R010070", mcode: cityCode)
            await MainActor.run {
                setupMenu(for: districtBtn, items: districts) { selected in
                    // 안드로이드의 selectedAreaScls = item.strIdx 로직
                    self.selectedAreaScls = selected.strIdx ?? "ALL"
                }
            }
        }
    }
    
    // UIButton에 드롭다운 메뉴 설정 (iOS 14+)
    private func setupMenu(for button: UIButton, items: [TxtListDataInfo], completion: @escaping (TxtListDataInfo) -> Void) {
        let menuItems = items.map { item in
            UIAction(title: item.strMsg ?? "", handler: { _ in
                button.setTitle(item.strMsg, for: .normal)
                completion(item)
            })
        }
        button.menu = UIMenu(title: "", children: menuItems)
        button.showsMenuAsPrimaryAction = true
    }

    // MARK: - Price Filter Logic

    private func setupPriceFilterUI() {
        priceSlider.minimumValue = 0
        priceSlider.maximumValue = 9990000
        priceSlider.value = 9990000
        updatePriceDisplay(isOn: priceFilterSwitch.isOn)
    }

    @IBAction func priceFilterSwitchChanged(_ sender: UISwitch) {
        UIView.animate(withDuration: 0.3) {
            self.updatePriceDisplay(isOn: sender.isOn)
        }
    }

    @IBAction func priceSliderValueChanged(_ sender: UISlider) {
        self.maxPrice = Int(sender.value)
        updatePriceLabelText()
    }

    private func updatePriceDisplay(isOn: Bool) {
        priceSlider.isHidden = !isOn
        priceRangeLabel.isHidden = !isOn
        if !isOn {
            maxPrice = 9990000
        } else {
            updatePriceLabelText()
        }
    }

    private func updatePriceLabelText() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedPrice = formatter.string(from: NSNumber(value: maxPrice)) ?? "0"
        priceRangeLabel.text = "0원 ~ \(formattedPrice)원"
    }

    // MARK: - Data Loading
    
    @objc func loadInitialData() {
        currentPage = 1
        isEndReached = false
        items.removeAll()
        tableView.reloadData()
        fetchProducts()
    }

    private func fetchProducts() {
        guard !isLoading && !isEndReached else { return }
        
        isLoading = true
        // 로딩 시작: 오버레이를 보여주고 애니메이션 시작
        loadingOverlay.isHidden = false
        loadingIndicator.startAnimating()
        
        let request = AdListRequest(
            token: TokenUtil.getToken() ?? "",
            adCode: 1,
            pageno: currentPage,
            categoryGroup: "R010610",
            categoryMid: selectedCategoryMid,
            categoryScls: "ALL",
            areaGroup: "R010070",
            areaMid: selectedAreaMid,
            areaScls: "ALL",
            minPrice: 0,
            maxPrice: maxPrice, // 슬라이더 값 적용
            saleStatus: saleSwitch.isOn ? "1" : "0",
            memberCode: ""
        )
        
        Task {
            do {
                let response = try await appService.getBuyAdvertiseList(req: request)
                
                await MainActor.run {
                    if !response.isEmpty {
                        self.items.append(contentsOf: response)
                        self.currentPage += 1
                        self.tableView.restore()
                        self.tableView.reloadData()
                    } else {
                        if self.currentPage == 1 {
                            self.tableView.setEmptyMessage("데이타가 없습니다.")
                        }
                        self.isEndReached = true
                    }
                    self.isLoading = false
                    self.loadingIndicator.stopAnimating()
                    self.loadingOverlay.isHidden = true
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.loadingIndicator.stopAnimating()
                    self.loadingOverlay.isHidden = true
                }
            }
        }
    }

    @IBAction func onInquiryTapped(_ sender: UIButton) {
        loadInitialData()
    }
}
// MARK: - UITableView 구현
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 1. 셀을 꺼내오되, 실패하면 로그를 남깁니다.
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductTableViewCell.reuseIdentifier, for: indexPath) as? ProductTableViewCell else {
            // 에러 발생 시 앱이 죽지 않게 기본 셀이라도 반환 (디버깅용)
            return UITableViewCell()
        }
        
        // 2. 이제 'cell'은 확실히 ProductTableViewCell 타입입니다.
        let item = items[indexPath.row]
        cell.configure(with: item)
        
        // 안드로이드 상세페이지 이동 처럼 '>' 모양 아이콘 추가
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == items.count - 1 {
            fetchProducts()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ProductDetailVC") as! ProductDetailViewController
        vc.productId = Int64(item.productId ?? "") ?? 0
        vc.productUserId = item.userId ?? ""
        vc.productTitle = item.title ?? ""
        navigationController?.pushViewController(vc, animated: true)
        
    }
}

