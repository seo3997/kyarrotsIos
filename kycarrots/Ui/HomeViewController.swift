import UIKit

final class HomeViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingOverlay: UIView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var categoryBtn: UIButton!
    @IBOutlet weak var subCategoryBtn: UIButton!
    @IBOutlet weak var areaBtn: UIButton!
    @IBOutlet weak var districtBtn: UIButton!
    @IBOutlet weak var saleSwitch: UISwitch!
    @IBOutlet weak var priceFilterSwitch: UISwitch!
    @IBOutlet weak var priceSliderStackView: UIStackView!
    @IBOutlet weak var buttonStackView: UIStackView!

    @IBOutlet weak var priceSlider: RangeSlider!
    @IBOutlet weak var priceRangeLabel: UILabel!
    @IBOutlet weak var searchBtn: UIButton! 
    // MARK: - Properties
    private let appService = AppServiceProvider.shared
    private var items: [AdItem] = []
    
    private var currentPage = 1
    private var isLoading = false
    private var isEndReached = false
    
    // 필터 데이터 (안드로이드 변수명과 매칭)
    private var selectedCategoryMid = "ALL"
    private var selectedCategoryScls = "ALL"
    private var selectedAreaMid = "ALL"
    private var selectedAreaScls = "ALL"
    private var minPrice: Int = 0
    private var maxPrice: Int = 9990000

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupPriceSlider()
        loadInitialFilterData() // 카테고리/지역 목록 가져오기
        loadInitialData()       // 초기 데이터 로드
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.title = "상품 리스트"
    }

    // MARK: - UI Setup
    private func setupUI() {
        self.navigationItem.title = "상품 리스트"
        loadingOverlay.isHidden = true
        loadingIndicator.hidesWhenStopped = true
        
        applyButtonStyle(to: categoryBtn)
        applyButtonStyle(to: subCategoryBtn)
        applyButtonStyle(to: areaBtn)
        applyButtonStyle(to: districtBtn)
        
        // 스위치 액션 연결 (스토리보드에서 연결 안 되어 있을 경우를 대비)
        saleSwitch.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        priceFilterSwitch.addTarget(self, action: #selector(priceFilterSwitchChanged), for: .valueChanged)
    }

    private func setupPriceSlider() {
        priceSlider.minimumValue = 0
        priceSlider.maximumValue = 9990000
        priceSlider.lowerValue = 0
        priceSlider.upperValue = 9990000
        priceSlider.addTarget(self, action: #selector(priceSliderValueChanged(_:)), for: .valueChanged)
        updatePriceDisplay(isOn: priceFilterSwitch.isOn)
    }

    private func applyButtonStyle(to button: UIButton?) {
        guard let btn = button else { return }
        let config = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        let arrowImage = UIImage(systemName: "chevron.down", withConfiguration: config)

        btn.setImage(arrowImage, for: .normal)
        btn.tintColor = .darkGray
        btn.contentHorizontalAlignment = .fill
        btn.semanticContentAttribute = .forceRightToLeft
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        btn.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        btn.layer.cornerRadius = 8
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.systemGray5.cgColor
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        btn.setTitleColor(.black, for: .normal)
        
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 38).isActive = true
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        let nib = UINib(nibName: "ProductTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: ProductTableViewCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 110
    }

    // MARK: - Actions
    @objc private func filterChanged() {
        // 안드로이드 applyFiltersAndReload() 처럼 즉시 재조회
        loadInitialData()
    }

    @objc private func priceFilterSwitchChanged(_ sender: UISwitch) {
        updatePriceDisplay(isOn: sender.isOn)
        loadInitialData()
    }

    @objc func priceSliderValueChanged(_ sender: RangeSlider) {
        let step: CGFloat = 10000
        sender.lowerValue = round(sender.lowerValue / step) * step
        sender.upperValue = round(sender.upperValue / step) * step
        
        self.minPrice = Int(sender.lowerValue)
        self.maxPrice = Int(sender.upperValue)
        updatePriceLabelText()
        
        // 슬라이더는 조작 중이므로 즉시 조회보다는 '조회' 버튼이나 다른 필터 변경 시 반영되게 둡니다.
        // 만약 손 뗄 때 바로 조회되길 원하면 UIControl.Event.editingDidEnd 등을 활용하세요.
    }

    @IBAction func onInquiryTapped(_ sender: UIButton) {
        loadInitialData()
    }

    // MARK: - Filter Data Loading
    private func loadInitialFilterData() {
        Task {
            // 카테고리 로드
            let cats = await appService.getCodeList(groupId: "R010610")
            setupMenu(for: categoryBtn, items: cats) { selected in
                self.selectedCategoryMid = selected.strIdx ?? "ALL"
                self.selectedCategoryScls = "ALL" // 대분류 변경 시 소분류 초기화
                self.subCategoryBtn.setTitle("전체", for: .normal)
                self.loadSubCategories(categoryMid: self.selectedCategoryMid)
                self.loadInitialData() // 즉시 조회
            }

            // 도시 로드
            let cityList = await appService.getCodeList(groupId: "R010070")
            setupMenu(for: areaBtn, items: cityList) { selected in
                self.selectedAreaMid = selected.strIdx ?? "ALL"
                self.selectedAreaScls = "ALL" // 도시 변경 시 구/군 초기화
                self.districtBtn.setTitle("전체", for: .normal)
                self.loadDistricts(cityCode: self.selectedAreaMid)
                self.loadInitialData() // 즉시 조회
            }
        }
    }

    private func loadSubCategories(categoryMid: String) {
        Task {
            let subCats = await appService.getSCodeList(groupId: "R010610", mcode: categoryMid)
            await MainActor.run {
                setupMenu(for: subCategoryBtn, items: subCats) { selected in
                    self.selectedCategoryScls = selected.strIdx ?? "ALL"
                    self.loadInitialData() // 즉시 조회
                }
            }
        }
    }

    private func loadDistricts(cityCode: String) {
        Task {
            let districts = await appService.getSCodeList(groupId: "R010070", mcode: cityCode)
            await MainActor.run {
                setupMenu(for: districtBtn, items: districts) { selected in
                    self.selectedAreaScls = selected.strIdx ?? "ALL"
                    self.loadInitialData() // 즉시 조회
                }
            }
        }
    }

    private func setupMenu(for button: UIButton, items: [TxtListDataInfo], completion: @escaping (TxtListDataInfo) -> Void) {
        var allEntry = TxtListDataInfo()
        allEntry.strIdx = "ALL"
        allEntry.strMsg = "전체"
        let fullList = [allEntry] + items
        
        let actions = fullList.map { item in
            UIAction(title: item.strMsg ?? "", handler: { _ in
                button.setTitle(item.strMsg, for: .normal)
                completion(item)
            })
        }
        button.menu = UIMenu(title: "", children: actions)
        button.showsMenuAsPrimaryAction = true
        if button.title(for: .normal) == nil || button.title(for: .normal)!.isEmpty {
            button.setTitle("전체", for: .normal)
        }
    }

    private func updatePriceDisplay(isOn: Bool) {
        // 1. 두 개의 스택뷰를 동시에 숨기거나 보여줍니다.
        priceSliderStackView.isHidden = !isOn
        buttonStackView.isHidden = !isOn
        
        // (만약 라벨이 스택뷰 밖에 있다면 라벨도 같이)
        priceRangeLabel.isHidden = !isOn
        
        if !isOn {
            // 스위치가 꺼지면 안드로이드 로직에 따라 필터 초기화 후 즉시 조회
            minPrice = 0
            maxPrice = 9990000
            priceSlider.lowerValue = 0
            priceSlider.upperValue = 9990000
            
            // 필터가 해제되었으므로 즉시 전체 데이터를 다시 불러옴
            loadInitialData()
        } else {
            // 스위치가 켜지면 현재 슬라이더 값에 맞게 텍스트 업데이트
            updatePriceLabelText()
        }

        // 2. 레이아웃 변화를 부드럽게 (애니메이션)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func updatePriceLabelText() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedMin = formatter.string(from: NSNumber(value: minPrice)) ?? "0"
        let formattedMax = formatter.string(from: NSNumber(value: maxPrice)) ?? "0"
        priceRangeLabel.text = "\(formattedMin)원 ~ \(formattedMax)원"
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
        loadingOverlay.isHidden = false
        loadingIndicator.startAnimating()
        
        let request = AdListRequest(
            token: TokenUtil.getToken() ?? "",
            adCode: 1,
            pageno: currentPage,
            categoryGroup: "R010610",
            categoryMid: selectedCategoryMid,
            categoryScls: selectedCategoryScls, // 선택된 소분류 반영
            areaGroup: "R010070",
            areaMid: selectedAreaMid,
            areaScls: selectedAreaScls,         // 선택된 구/군 반영
            minPrice: self.minPrice,
            maxPrice: self.maxPrice,
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
                            self.tableView.setEmptyMessage("데이터가 없습니다.")
                        }
                        self.isEndReached = true
                    }
                    self.finishLoading()
                }
            } catch {
                await MainActor.run { self.finishLoading() }
            }
        }
    }

    private func finishLoading() {
        self.isLoading = false
        self.loadingIndicator.stopAnimating()
        self.loadingOverlay.isHidden = true
    }
}

// MARK: - UITableView 구현
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductTableViewCell.reuseIdentifier, for: indexPath) as? ProductTableViewCell else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        cell.configure(with: item)
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
        if let vc = storyboard.instantiateViewController(withIdentifier: "ProductDetailVC") as? ProductDetailViewController {
            vc.productId = Int64(item.productId ?? "") ?? 0
            vc.productUserId = item.userId ?? ""
            vc.productTitle = item.title ?? ""
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
