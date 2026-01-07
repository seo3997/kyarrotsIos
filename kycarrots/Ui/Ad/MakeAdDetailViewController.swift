import UIKit

/// 스토리보드용 (탭 없음) - 폼 + 하단 다음 버튼
final class MakeAdDetailViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    // MARK: - Dependencies (Storyboard에서는 init 주입 불가 → 외부에서 할당)
    var service: AppService!

    // callbacks
    var onCategoryMidChanged: ((String) -> Void)?
    var onAreaMidChanged: ((String) -> Void)?
    var onRequestGoImageTab: (() -> Void)?

    // MARK: - IBOutlets (스토리보드에서 연결)
    @IBOutlet weak var tfName: UITextField!
    @IBOutlet weak var tfQuantity: UITextField!
    @IBOutlet weak var btnUnit: UIButton!

    @IBOutlet weak var tfAmount: UITextField!
    @IBOutlet weak var tfDesiredDate: UITextField!

    @IBOutlet weak var tvDetail: UITextView!

    @IBOutlet weak var btnCategoryMid: UIButton!
    @IBOutlet weak var btnCategorySub: UIButton!
    @IBOutlet weak var btnAreaMid: UIButton!
    @IBOutlet weak var btnAreaSub: UIButton!

    @IBOutlet weak var btnNext: UIButton!

    // MARK: - State (선택 코드 저장)
    private var selectedCategoryMidCode: String?
    private var selectedCategorySubCode: String?
    private var selectedAreaMidCode: String?
    private var selectedAreaSubCode: String?
    private var selectedUnitCode: String?

    // code lists
    private var categoryMidList: [TxtListDataInfo] = []
    private var categorySubList: [TxtListDataInfo] = []
    private var areaMidList: [TxtListDataInfo] = []
    private var areaSubList: [TxtListDataInfo] = []
    private var unitList: [TxtListDataInfo] = []

    // DatePicker
    private let datePicker = UIDatePicker()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(service != nil, "MakeAdDetailViewController.service 가 주입되지 않았습니다. 화면 띄우기 전에 vc.service = ... 해주세요.")

        setupUI()
        setupKeyboardDismiss()
        loadCodes()
    }

    // MARK: - UI Setup
    private func setupUI() {
        // TextField
        tfName.delegate = self
        tfAmount.delegate = self
        tfQuantity.delegate = self
        tfDesiredDate.delegate = self

        tfName.returnKeyType = .done
        tfDesiredDate.returnKeyType = .done

        tfAmount.keyboardType = .numberPad
        tfQuantity.keyboardType = .numberPad

        // 숫자키보드 done toolbar
        let numberToolbar = makeNumberToolbar()
        tfAmount.inputAccessoryView = numberToolbar
        tfQuantity.inputAccessoryView = numberToolbar

        // 날짜 picker
        setupDatePicker()

        // TextView
        tvDetail.delegate = self
        tvDetail.layer.borderWidth = 1
        tvDetail.layer.borderColor = UIColor.systemGray4.cgColor
        tvDetail.layer.cornerRadius = 8
        tvDetail.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)

        // 선택 버튼 스타일
        styleSelectButton(btnUnit)
        styleSelectButton(btnCategoryMid)
        styleSelectButton(btnCategorySub)
        styleSelectButton(btnAreaMid)
        styleSelectButton(btnAreaSub)

        // Next 버튼 스타일(원하면 스토리보드에서 처리해도 됨)
        btnNext.layer.cornerRadius = 10
    }

    private func styleSelectButton(_ b: UIButton) {
        b.contentHorizontalAlignment = .left
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.systemGray4.cgColor
        b.layer.cornerRadius = 8
        b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    }

    private func setupDatePicker() {
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "ko_KR")

        tfDesiredDate.inputView = datePicker

        let bar = UIToolbar()
        bar.sizeToFit()
        bar.items = [
            UIBarButtonItem(title: "취소", style: .plain, target: self, action: #selector(onCancelDate)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "확인", style: .done, target: self, action: #selector(onConfirmDate))
        ]
        tfDesiredDate.inputAccessoryView = bar
    }

    @objc private func onCancelDate() {
        tfDesiredDate.resignFirstResponder()
    }

    @objc private func onConfirmDate() {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        tfDesiredDate.text = f.string(from: datePicker.date)
        tfDesiredDate.resignFirstResponder()
    }

    // MARK: - Load Codes
    private func loadCodes() {
        Task {
            do {
                // 그룹코드 id는 기존 서버 규칙대로
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

    // 외부에서 sub list 주입 (MakeAdMainViewController가 호출)
    func setSubCategoryList(_ list: [TxtListDataInfo]) {
        self.categorySubList = list
        self.selectedCategorySubCode = nil
        btnCategorySub.setTitle("카테고리(소) 선택", for: .normal)
    }

    func setSubAreaList(_ list: [TxtListDataInfo]) {
        self.areaSubList = list
        self.selectedAreaSubCode = nil
        btnAreaSub.setTitle("지역(소) 선택", for: .normal)
    }

    // MARK: - Draft Binding
    func applyDraft(_ d: MakeAdDraft) {
        tfName.text = d.name
        tfAmount.text = d.amount
        tfQuantity.text = d.quantity
        tfDesiredDate.text = d.desiredShippingDate
        tvDetail.text = d.detail

        selectedCategoryMidCode = d.categoryMid
        selectedCategorySubCode = d.categoryScls
        selectedAreaMidCode = d.areaMid
        selectedAreaSubCode = d.areaScls
        selectedUnitCode = d.unitCode

        if let nm = d.categoryMidName { btnCategoryMid.setTitle(nm, for: .normal) }
        if let nm = d.categorySclsName { btnCategorySub.setTitle(nm, for: .normal) }
        if let nm = d.areaMidName { btnAreaMid.setTitle(nm, for: .normal) }
        if let nm = d.areaSclsName { btnAreaSub.setTitle(nm, for: .normal) }
        if let nm = d.unitName { btnUnit.setTitle(nm, for: .normal) }
    }

    func collectDraft(into base: MakeAdDraft) -> MakeAdDraft? {
        var d = base
        d.name = (tfName.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        d.amount = (tfAmount.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        d.quantity = (tfQuantity.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        d.desiredShippingDate = (tfDesiredDate.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        d.detail = tvDetail.text.trimmingCharacters(in: .whitespacesAndNewlines)

        d.categoryMid = selectedCategoryMidCode ?? d.categoryMid
        d.categoryScls = selectedCategorySubCode ?? d.categoryScls
        d.areaMid = selectedAreaMidCode ?? d.areaMid
        d.areaScls = selectedAreaSubCode ?? d.areaScls
        d.unitCode = selectedUnitCode ?? d.unitCode

        if d.name.isEmpty { toast("상품명을 입력해 주세요"); return nil }
        if d.amount.isEmpty { toast("금액을 입력해 주세요"); return nil }
        if d.quantity.isEmpty { toast("수량을 입력해 주세요"); return nil }
        if (d.desiredShippingDate ?? "").isEmpty {
            toast("희망 출하일을 선택해 주세요")
            return nil
        }
        if (d.categoryMid ?? "").isEmpty { toast("카테고리를 선택해 주세요"); return nil }
        if (d.areaMid ?? "").isEmpty { toast("지역을 선택해 주세요"); return nil }
        if (d.unitCode ?? "").isEmpty { toast("단위를 선택해 주세요"); return nil }

        return d
    }

    // MARK: - IBActions
    @IBAction func onPickUnit(_ sender: UIButton) {
        pick(from: unitList, title: "단위 선택", anchor: sender) { [weak self] item in
            guard let self else { return }
            self.btnUnit.setTitle(item.strMsg, for: .normal)
            self.selectedUnitCode = item.strIdx
        }
    }

    @IBAction func onPickCategoryMid(_ sender: UIButton) {
        pick(from: categoryMidList, title: "카테고리(중) 선택", anchor: sender) { [weak self] item in
            guard let self else { return }

            self.btnCategoryMid.setTitle(item.strMsg, for: .normal)
            self.selectedCategoryMidCode = item.strIdx

            // 중 변경 시 소 초기화
            self.selectedCategorySubCode = nil
            self.categorySubList = []
            self.btnCategorySub.setTitle("카테고리(소) 선택", for: .normal)

            // MakeAdMain에게 sub 목록 요청
            self.onCategoryMidChanged?(item.strIdx)
        }
    }

    @IBAction func onPickCategorySub(_ sender: UIButton) {
        pick(from: categorySubList, title: "카테고리(소) 선택", anchor: sender) { [weak self] item in
            guard let self else { return }
            self.btnCategorySub.setTitle(item.strMsg, for: .normal)
            self.selectedCategorySubCode = item.strIdx
        }
    }

    @IBAction func onPickAreaMid(_ sender: UIButton) {
        pick(from: areaMidList, title: "지역(중) 선택", anchor: sender) { [weak self] item in
            guard let self else { return }

            self.btnAreaMid.setTitle(item.strMsg, for: .normal)
            self.selectedAreaMidCode = item.strIdx

            // 중 변경 시 소 초기화
            self.selectedAreaSubCode = nil
            self.areaSubList = []
            self.btnAreaSub.setTitle("지역(소) 선택", for: .normal)

            // MakeAdMain에게 sub 목록 요청
            self.onAreaMidChanged?(item.strIdx)
        }
    }

    @IBAction func onPickAreaSub(_ sender: UIButton) {
        pick(from: areaSubList, title: "지역(소) 선택", anchor: sender) { [weak self] item in
            guard let self else { return }
            self.btnAreaSub.setTitle(item.strMsg, for: .normal)
            self.selectedAreaSubCode = item.strIdx
        }
    }

    @IBAction func onNextTapped(_ sender: UIButton) {
        // “다음” 누르면 탭 이동(이미지등록)만 요청
        if (tfName.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            toast("상품명을 입력해 주세요")
            return
        }
        onRequestGoImageTab?()
    }

    // MARK: - Picker (ActionSheet)
    private func pick(
        from list: [TxtListDataInfo],
        title: String,
        anchor: UIView,
        onPick: @escaping (TxtListDataInfo) -> Void
    ) {
        guard !list.isEmpty else { toast("목록이 없습니다"); return }

        let ac = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        // 길면 임시로 20개만. (필요하면 '더보기'로 확장 가능)
        for item in list.prefix(20) {
            ac.addAction(UIAlertAction(title: item.strMsg, style: .default) { _ in onPick(item) })
        }
        ac.addAction(UIAlertAction(title: "취소", style: .cancel))

        // iPad 대응
        if let pop = ac.popoverPresentationController {
            pop.sourceView = anchor
            pop.sourceRect = anchor.bounds
        }

        present(ac, animated: true)
    }

    // MARK: - Keyboard
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingAll))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func endEditingAll() {
        view.endEditing(true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func makeNumberToolbar() -> UIToolbar {
        let bar = UIToolbar()
        bar.sizeToFit()

        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(doneTapped))

        bar.items = [flex, done]
        return bar
    }

    @objc private func doneTapped() {
        view.endEditing(true)
    }

    // MARK: - Toast
    private func toast(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}
