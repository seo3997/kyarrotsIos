import UIKit

/// Android MembershipActivity.kt 를 iOS(Storyboard)로 이식한 버전
/// - 이메일 중복확인 필수
/// - 생년월일 YYYY-MM-DD
/// - 전화번호 ^01[016789]-\d{3,4}-\d{4}$
/// - 성별 필수(남=1, 여=2)
/// - 지역(시/도 + 구/군) 필수
/// - 사용자구분 필수 (SYSTEM_TYPE 규칙)
final class MembershipViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Dependencies (Storyboard에서는 init 주입 불가 → 외부에서 할당)
    var service: AppService!

    // MARK: - IBOutlets
    @IBOutlet weak var tfName: UITextField!
    @IBOutlet weak var tfEmail: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var tfPasswordConfirm: UITextField!
    @IBOutlet weak var tfBirth: UITextField!
    @IBOutlet weak var tfPhoneMid: UITextField!
    @IBOutlet weak var tfPhoneLast: UITextField!

    @IBOutlet weak var btnPhoneFirst: UIButton!
    @IBOutlet weak var btnCity: UIButton!
    @IBOutlet weak var btnTown: UIButton!
    @IBOutlet weak var btnRole: UIButton!

    @IBOutlet weak var segGender: UISegmentedControl!

    @IBOutlet weak var btnCheckEmail: UIButton!
    @IBOutlet weak var btnRegister: UIButton!

    @IBOutlet weak var loadingOverlay: UIView!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!

    // MARK: - State
    private var isEmailChecked = false

    private let phoneFirstList = ["010","011","016","017","018","019"]
    private var selectedPhoneFirst = "010"

    // 지역 코드 목록 (Android: getCodeList("R010070"), getSCodeList("R010070", cityCode))
    private var cityList: [TxtListDataInfo] = []
    private var townList: [TxtListDataInfo] = []

    private var selectedCityCode: String = ""
    private var selectedTownCode: String = ""

    // 사용자구분 (Android roleMap)
    private lazy var roleMap: [String: String] = {
        if Constants.SYSTEM_TYPE == 1 {
            return ["판매자":"ROLE_SELL", "구매자":"ROLE_PUB"]
        } else {
            return ["판매자":"ROLE_SELL", "센터관리":"ROLE_PROJ", "구매자":"ROLE_PUB"]
        }
    }()
    private var selectedRoleCode: String = ""

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(service != nil, "MembershipViewController.service 가 주입되지 않았습니다. 화면 띄우기 전에 vc.service = ... 해주세요.")
        navigationItem.title = "회원가입"

        setupUI()
        setupKeyboardDismiss()
        setupWatchers()
        resetTownSelectionUI()
        showLoading(false)

        loadCityList()
    }

    // MARK: - UI Setup
    private func setupUI() {
        // TextField delegate
        [
            tfName,
            tfEmail,
            tfPassword,
            tfPasswordConfirm,
            tfBirth,
            tfPhoneMid,
            tfPhoneLast
        ].forEach { tf in
            tf?.delegate = self              // ✅ 기존 기능 유지
            tf?.applyFormFieldStyle()        // ✅ 공통 둥근 스타일
            tf?.setLeftPadding(14)
            tf?.heightAnchor.constraint(equalToConstant: 48).isActive = true
        }

        
        tfEmail.autocapitalizationType = .none
        tfEmail.keyboardType = .emailAddress

        tfPassword.isSecureTextEntry = true
        tfPasswordConfirm.isSecureTextEntry = true

        tfBirth.keyboardType = .numberPad
        tfPhoneMid.keyboardType = .numberPad
        tfPhoneLast.keyboardType = .numberPad

        // 스타일(네 프로젝트 기존 폼 스타일과 동일하게)
        styleTextField(tfName)
        styleTextField(tfEmail)
        styleTextField(tfPassword)
        styleTextField(tfPasswordConfirm)
        styleTextField(tfBirth)
        styleTextField(tfPhoneMid)
        styleTextField(tfPhoneLast)

        stylePillButton(btnPhoneFirst)
        stylePillButton(btnCity)
        stylePillButton(btnTown)
        stylePillButton(btnRole)

        btnRegister.layer.cornerRadius = 10

        // 기본값
        selectedPhoneFirst = "010"
        btnPhoneFirst.setTitle(selectedPhoneFirst, for: .normal)

        btnCity.setTitle("시/도 선택", for: .normal)
        btnTown.setTitle("구/군 선택", for: .normal)
        btnRole.setTitle("사용자구분 선택", for: .normal)

        // 성별 세그먼트
        segGender.removeAllSegments()
        segGender.insertSegment(withTitle: "남", at: 0, animated: false)
        segGender.insertSegment(withTitle: "여", at: 1, animated: false)
        segGender.selectedSegmentIndex = UISegmentedControl.noSegment
    }

    private func styleTextField(_ t: UITextField) {
        t.borderStyle = .none
        t.layer.cornerRadius = 12
        t.layer.borderWidth = 1
        t.layer.borderColor = UIColor.systemGray4.cgColor
        t.backgroundColor = .white
        t.setLeftPadding(14)
        t.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    private func stylePillButton(_ b: UIButton) {
        b.contentHorizontalAlignment = .left
        b.layer.cornerRadius = 12
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.systemGray4.cgColor
        b.backgroundColor = .white
        b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    // MARK: - Watchers (Android TextWatcher/YmdDateWatcher 동일)
    private func setupWatchers() {
        // 이메일 변경 시 중복확인 다시 필요
        tfEmail.addTarget(self, action: #selector(onEmailChanged), for: .editingChanged)

        // 생년월일 YYYY-MM-DD 자동 포맷
        tfBirth.addTarget(self, action: #selector(onBirthChanged), for: .editingChanged)

        // 숫자키보드 Done toolbar (선택사항)
        let numberToolbar = makeNumberToolbar()
        tfBirth.inputAccessoryView = numberToolbar
        tfPhoneMid.inputAccessoryView = numberToolbar
        tfPhoneLast.inputAccessoryView = numberToolbar
    }

    @objc private func onEmailChanged() {
        isEmailChecked = false
    }

    @objc private func onBirthChanged() {
        // 숫자만 남기고 YYYY-MM-DD로 자동 보정 (Android YmdDateWatcher 느낌)
        let raw = (tfBirth.text ?? "").replacingOccurrences(of: "-", with: "")
        let digits = raw.filter { $0.isNumber }
        var out = ""
        for (i, ch) in digits.enumerated() {
            if i == 4 || i == 6 { out.append("-") }
            if out.count >= 10 { break }
            out.append(ch)
        }
        if tfBirth.text != out { tfBirth.text = out }
    }

    // MARK: - IBActions (Pick)
    @IBAction func onPickPhoneFirst(_ sender: UIButton) {
        pickSimple(title: "번호 선택", options: phoneFirstList, anchor: sender) { [weak self] v in
            guard let self else { return }
            self.selectedPhoneFirst = v
            self.btnPhoneFirst.setTitle(v, for: .normal)
        }
    }

    @IBAction func onPickCity(_ sender: UIButton) {
        pick(from: cityList, title: "시/도 선택", anchor: sender) { [weak self] item in
            guard let self else { return }
            self.selectedCityCode = item.strIdx
            self.btnCity.setTitle(item.strMsg, for: .normal)

            // 시/도 변경 시 구/군 초기화 (Android resetTownSelection 동일)
            self.selectedTownCode = ""
            self.btnTown.setTitle("구/군 선택", for: .normal)
            self.resetTownSelectionUI()
            self.loadTownList(cityCode: item.strIdx)
        }
    }

    @IBAction func onPickTown(_ sender: UIButton) {
        if selectedCityCode.isEmpty {
            toast("먼저 시/도를 선택하세요.")
            return
        }
        pick(from: townList, title: "구/군 선택", anchor: sender) { [weak self] item in
            guard let self else { return }
            self.selectedTownCode = item.strIdx
            self.btnTown.setTitle(item.strMsg, for: .normal)
        }
    }

    @IBAction func onPickRole(_ sender: UIButton) {
        let roles = Array(roleMap.keys)
        pickSimple(title: "사용자구분 선택", options: roles, anchor: sender) { [weak self] key in
            guard let self else { return }
            self.selectedRoleCode = self.roleMap[key] ?? ""
            self.btnRole.setTitle(key, for: .normal)
        }
    }

    // MARK: - Email Check / Register
    @IBAction func onCheckEmail(_ sender: UIButton) {
        let email = (tfEmail.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(email) else {
            toast("유효한 이메일을 입력하세요.")
            return
        }

        showLoading(true)
        Task {
            let ok = await service.checkEmailDuplicate(email: email) // Android: response.result true => 사용 가능
            await MainActor.run {
                self.showLoading(false)
                if ok {
                    self.toast("사용 가능한 이메일입니다.")
                    self.isEmailChecked = true
                } else {
                    self.toast("이미 사용 중인 이메일입니다.")
                    self.isEmailChecked = false
                }
            }
        }
    }

    @IBAction func onRegister(_ sender: UIButton) {
        let name = (tfName.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let email = (tfEmail.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let password = (tfPassword.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let birth = (tfBirth.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordConfirm = (tfPasswordConfirm.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let phone = "\(selectedPhoneFirst)-\(tfPhoneMid.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")-\(tfPhoneLast.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")"

        let gender: String = {
            if segGender.selectedSegmentIndex == 0 { return "1" }  // 남
            if segGender.selectedSegmentIndex == 1 { return "2" }  // 여
            return ""
        }()

        // ✅ Android MembershipActivity.kt 검증 그대로
        if name.isEmpty { toast("이름을 입력하세요."); return }
        if !isValidEmail(email) { toast("유효한 이메일을 입력하세요."); return }
        if !isEmailChecked { toast("이메일 중복 확인을 해주세요."); return }
        if password.count < 4 { toast("비밀번호는 최소 4자 이상이어야 합니다."); return }
        if password != passwordConfirm {
            toast("비밀번호가 일치하지 않습니다.")
            return
        }
        if birth.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) == nil {
            toast("생년월일은 YYYY-MM-DD 형식으로 입력하세요.")
            return
        }
        if phone.range(of: #"^01[016789]-\d{3,4}-\d{4}$"#, options: .regularExpression) == nil {
            toast("유효한 전화번호를 입력하세요.")
            return
        }
        if gender.isEmpty { toast("성별을 선택하세요."); return }
        if selectedCityCode.isEmpty || selectedTownCode.isEmpty { toast("지역을 모두 선택하세요."); return }
        if selectedRoleCode.isEmpty { toast("사용자구분을 선택하세요."); return }

        // ✅ 서버 DTO는 네 프로젝트 OpUserVO에 맞춰서 매핑
        var user = OpUserVO()
        user.userNm = name
        user.email = email
        user.userId = email              // Android도 userId = email
        user.password = password
        // 전화
        user.cttpc = phone               // "010-1234-5678"
        user.cttpcSeCode = ""            // 서버에서 필요하면(예: "MOBILE") 코드값 세팅. 없으면 빈값
        // 성별
        user.gender = Int(gender)        // "1"/"2" -> Int
        // 생년월일
        user.birthDate = birth
        // 지역(필수)
        user.areaCode = selectedCityCode         // 시/도 코드
        user.areaSeCodeS = selectedTownCode      // 구/군 코드
        user.areaSeCodeD = ""                    // Android도 ""로 보냈음(동/읍/면 단계 있으면 여기에)
        // 상태/가입경로
        user.userSttusCode = "10"        // Android에서 "10" 사용
        user.memberCode = selectedRoleCode
        user.provider = "PWD"            // Android "PWD"
        // 추천인/기타(없으면 빈값)
        user.referrerId = ""             // Android referrerId = ""
        user.userAge = ""                // Android userAge = ""
        showLoading(true)
        Task {
            let ok = await service.registerUser(user)
            await MainActor.run {
                self.showLoading(false)
                if ok {
                    self.toast("회원가입 성공!")
                    // Android는 MainNavigation.goMain(...)로 이동.
                    // iOS는 네 앱 흐름에 맞게 처리 (예: popToRoot / coordinator showHome 등)
                    self.navigationController?.popToRootViewController(animated: true)
                } else {
                    self.toast("회원가입 실패")
                }
            }
        }
    }

    // MARK: - Load Codes (Android loadCityList/loadTownList 동일)
    private func loadCityList() {
        Task {
            do {
                // Android: getCodeList("R010070")
                let list = try await service.getCodeList(groupId: "R010070")
                await MainActor.run {
                    self.cityList = list
                }
            } catch {
                await MainActor.run { self.toast("지역 목록 불러오기 실패") }
            }
        }
    }

    private func loadTownList(cityCode: String) {
        Task {
            do {
                // Android: getSCodeList("R010070", selectedCityValue)
                let list = try await service.getSCodeList(groupId: "R010070", mcode: cityCode)
                await MainActor.run {
                    self.townList = list
                    self.btnTown.isEnabled = true
                    self.btnTown.alpha = 1.0
                }
            } catch {
                await MainActor.run { self.toast("지역 목록 불러오기 실패") }
            }
        }
    }

    private func resetTownSelectionUI() {
        btnTown.isEnabled = false
        btnTown.alpha = 0.6
        townList = []
    }

    // MARK: - Picker (ActionSheet)  — MakeAdDetailViewController 스타일
    private func pick(
        from list: [TxtListDataInfo],
        title: String,
        anchor: UIView,
        onPick: @escaping (TxtListDataInfo) -> Void
    ) {
        guard !list.isEmpty else { toast("목록이 없습니다"); return }

        let ac = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        for item in list.prefix(30) {
            ac.addAction(UIAlertAction(title: item.strMsg, style: .default) { _ in onPick(item) })
        }
        ac.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = anchor
            pop.sourceRect = anchor.bounds
        }
        present(ac, animated: true)
    }

    private func pickSimple(
        title: String,
        options: [String],
        anchor: UIView,
        onPick: @escaping (String) -> Void
    ) {
        guard !options.isEmpty else { toast("목록이 없습니다"); return }

        let ac = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        for v in options {
            ac.addAction(UIAlertAction(title: v, style: .default) { _ in onPick(v) })
        }
        ac.addAction(UIAlertAction(title: "취소", style: .cancel))

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
        let done = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(endEditingAll))
        bar.items = [flex, done]
        return bar
    }

    // MARK: - Loading
    private func showLoading(_ show: Bool) {
        loadingOverlay.isHidden = !show
        if show { loadingSpinner.startAnimating() } else { loadingSpinner.stopAnimating() }
        view.isUserInteractionEnabled = !show
    }

    // MARK: - Toast (MakeAdDetailViewController 스타일)
    private func toast(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
