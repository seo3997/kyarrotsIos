import UIKit

/// Kotlin: KtMakeADDetailView 대응 (상세 입력 화면)
final class MakeAdDetailViewController: UIViewController {

    private let service: AppService

    // callbacks
    var onCategoryMidChanged: ((String) -> Void)?

    // UI (간단한 폼)
    private let scroll = UIScrollView()
    private let stack = UIStackView()

    private let tfName = UITextField()
    private let tfAmount = UITextField()
    private let tfQuantity = UITextField()
    private let tfDesiredDate = UITextField()
    private let tvDetail = UITextView()

    private let btnCategoryMid = UIButton(type: .system)
    private let btnCategorySub = UIButton(type: .system)
    private let btnAreaMid = UIButton(type: .system)
    private let btnAreaSub = UIButton(type: .system)
    private let btnUnit = UIButton(type: .system)

    // code lists
    private var categoryMidList: [TxtListDataInfo] = []
    private var categorySubList: [TxtListDataInfo] = []
    private var areaMidList: [TxtListDataInfo] = []
    private var areaSubList: [TxtListDataInfo] = []
    private var unitList: [TxtListDataInfo] = []

    init(service: AppService) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        loadCodes()
    }

    private func setupUI() {
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stack.axis = .vertical
        stack.spacing = 12
        scroll.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16)
        ])

        tfName.placeholder = "상품명"
        tfAmount.placeholder = "금액"
        tfAmount.keyboardType = .numberPad
        tfQuantity.placeholder = "수량"
        tfQuantity.keyboardType = .numberPad
        tfDesiredDate.placeholder = "희망 발송일 (YYYY-MM-DD)"

        tvDetail.layer.borderWidth = 1
        tvDetail.layer.borderColor = UIColor.systemGray4.cgColor
        tvDetail.layer.cornerRadius = 8
        tvDetail.heightAnchor.constraint(equalToConstant: 140).isActive = true

        configButton(btnCategoryMid, title: "카테고리(중) 선택")
        configButton(btnCategorySub, title: "카테고리(소) 선택")
        configButton(btnAreaMid, title: "지역(중) 선택")
        configButton(btnAreaSub, title: "지역(소) 선택")
        configButton(btnUnit, title: "단위 선택")

        btnCategoryMid.addTarget(self, action: #selector(pickCategoryMid), for: .touchUpInside)
        btnCategorySub.addTarget(self, action: #selector(pickCategorySub), for: .touchUpInside)
        btnAreaMid.addTarget(self, action: #selector(pickAreaMid), for: .touchUpInside)
        btnAreaSub.addTarget(self, action: #selector(pickAreaSub), for: .touchUpInside)
        btnUnit.addTarget(self, action: #selector(pickUnit), for: .touchUpInside)

        stack.addArrangedSubview(tfName)
        stack.addArrangedSubview(tfAmount)
        stack.addArrangedSubview(tfQuantity)
        stack.addArrangedSubview(btnUnit)
        stack.addArrangedSubview(tfDesiredDate)

        stack.addArrangedSubview(btnCategoryMid)
        stack.addArrangedSubview(btnCategorySub)

        stack.addArrangedSubview(btnAreaMid)
        stack.addArrangedSubview(btnAreaSub)

        let lbl = UILabel()
        lbl.text = "상세 설명"
        lbl.font = .systemFont(ofSize: 14, weight: .semibold)
        stack.addArrangedSubview(lbl)
        stack.addArrangedSubview(tvDetail)

        // textfield 기본 스타일
        [tfName, tfAmount, tfQuantity, tfDesiredDate].forEach {
            $0.borderStyle = .roundedRect
        }
    }

    private func configButton(_ b: UIButton, title: String) {
        b.setTitle(title, for: .normal)
        b.contentHorizontalAlignment = .left
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.systemGray4.cgColor
        b.layer.cornerRadius = 8
        b.heightAnchor.constraint(equalToConstant: 44).isActive = true
        b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    }

    private func loadCodes() {
        Task {
            do {
                // Android: getCodeList("R010610"), getCodeList("R010070"), getCodeList("R010620")
                async let cat = service.getCodeList(groupId: "R010610")
                async let area = service.getCodeList(groupId: "R010070")
                async let unit = service.getCodeList(groupId: "R010620")

                let (catList, areaList, unitList) = try await (cat, area, unit)

                await MainActor.run {
                    self.categoryMidList = catList
                    self.areaMidList = areaList
                    self.unitList = unitList
                }
            } catch {
                await MainActor.run { self.toast("코드 불러오기 실패") }
            }
        }
    }

    // 외부에서 subCategory 리스트 주입 (Android: setSubCategoryList)
    func setSubCategoryList(_ list: [TxtListDataInfo]) {
        self.categorySubList = list
        btnCategorySub.setTitle("카테고리(소) 선택", for: .normal)
    }

    func applyDraft(_ d: MakeAdDraft) {
        tfName.text = d.name
        tfAmount.text = d.amount
        tfQuantity.text = d.quantity
        tfDesiredDate.text = d.desiredShippingDate
        tvDetail.text = d.detail

        if let nm = d.categoryMidName { btnCategoryMid.setTitle(nm, for: .normal) }
        if let nm = d.categorySclsName { btnCategorySub.setTitle(nm, for: .normal) }
        if let nm = d.areaMidName { btnAreaMid.setTitle(nm, for: .normal) }
        if let nm = d.areaSclsName { btnAreaSub.setTitle(nm, for: .normal) }
        if let nm = d.unitName { btnUnit.setTitle(nm, for: .normal) }
    }

    /// Main에서 미리보기 눌렀을 때 Draft 수집/검증
    func collectDraft(into base: MakeAdDraft) -> MakeAdDraft? {
        var d = base
        d.name = (tfName.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        d.amount = (tfAmount.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        d.quantity = (tfQuantity.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        d.desiredShippingDate = (tfDesiredDate.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        d.detail = tvDetail.text.trimmingCharacters(in: .whitespacesAndNewlines)

        // 최소 검증 (Android KtMakeADDetailView 기준으로 필요한 것만)
        if d.name.isEmpty { toast("상품명을 입력해 주세요"); return nil }
        if d.amount.isEmpty { toast("금액을 입력해 주세요"); return nil }
        if (d.categoryMid ?? "").isEmpty { toast("카테고리를 선택해 주세요"); return nil }
        if (d.areaMid ?? "").isEmpty { toast("지역을 선택해 주세요"); return nil }
        if (d.unitCode ?? "").isEmpty { toast("단위를 선택해 주세요"); return nil }
        return d
    }

    // MARK: - Pickers (간단 ActionSheet)
    @objc private func pickCategoryMid() { pick(from: categoryMidList, title: "카테고리(중) 선택") { [weak self] item in
        guard let self else { return }
        self.btnCategoryMid.setTitle(item.strMsg, for: .normal)
        self.categorySubList = []
        self.btnCategorySub.setTitle("카테고리(소) 선택", for: .normal)
        // draft 업데이트는 collectDraft에서 반영
        self.onCategoryMidChanged?(item.strIdx)
    } }

    @objc private func pickCategorySub() { pick(from: categorySubList, title: "카테고리(소) 선택") { [weak self] item in
        self?.btnCategorySub.setTitle(item.strMsg, for: .normal)
    } }

    @objc private func pickAreaMid() { pick(from: areaMidList, title: "지역(중) 선택") { [weak self] item in
        self?.btnAreaMid.setTitle(item.strMsg, for: .normal)
    } }

    @objc private func pickAreaSub() { pick(from: areaSubList, title: "지역(소) 선택") { [weak self] item in
        self?.btnAreaSub.setTitle(item.strMsg, for: .normal)
    } }

    @objc private func pickUnit() { pick(from: unitList, title: "단위 선택") { [weak self] item in
        self?.btnUnit.setTitle(item.strMsg, for: .normal)
    } }

    private func pick(
        from list: [TxtListDataInfo],
        title: String,
        onPick: @escaping (TxtListDataInfo) -> Void
    ) {
        guard !list.isEmpty else { toast("목록이 없습니다"); return }

        let ac = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        for item in list.prefix(20) {
            ac.addAction(UIAlertAction(title: item.strMsg, style: .default) { _ in
                onPick(item)
            })
        }

        ac.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }

        present(ac, animated: true)
    }

    
    private func toast(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}
