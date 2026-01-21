import UIKit

final class OnboardingViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Inject
    var service: AppService!
    weak var coordinator: AppCoordinator?
    var pendingDeepLink: PushDeepLink?

    // Social inputs (LoginVC에서 주입)
    var provider: String = "KAKAO"   // KAKAO / NAVER / GOOGLE / APPLE ...
    var providerUserId: String = ""
    var presetEmail: String = ""
    var presetNickname: String = ""

    // MARK: - IBOutlets (Membership와 동일 네이밍 + formContainer)
    @IBOutlet weak var formContainer: UIView!

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

    // (선택) 상태 메시지 라벨이 있으면 연결 (없으면 nil OK)
    @IBOutlet weak var emailStatusLabel: UILabel?

    // MARK: - State
    private var isEmailChecked = false
    private var selectedPhoneFirst = "010"
    // phone first options (010/011/016/017/018/019)
    private let phoneFirstOptions = ["010", "011", "016", "017", "018", "019"]

    // 지역/역할 (Membership 방식)
    private var cityList: [TxtListDataInfo] = []
    private var townList: [TxtListDataInfo] = []
    private var selectedCityCode: String = ""
    private var selectedTownCode: String = ""

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

        assert(service != nil, "OnboardingViewController.service 주입 필요")

        title = "추가정보입력"
        setupUI()
        setupWatchers()
        setupKeyboardDismiss()

        // preset
        tfEmail.text = presetEmail
        if !presetNickname.isEmpty { tfName.text = presetNickname }

        // load initial lists
        resetTownSelectionUI()
        loadCityList()

        // 이메일 확인 전에는 폼 숨김
        closeForm()
    }

    // MARK: - UI Setup
    private func setupUI() {
        // ✅ 로딩 초기화
        showLoading(false)

        // ✅ TextField 공통 세팅 (delegate + 공통 스타일 + 패딩 + 높이)
        [
            tfName,
            tfEmail,
            tfPassword,
            tfPasswordConfirm,
            tfBirth,
            tfPhoneMid,
            tfPhoneLast
        ].forEach { tf in
            tf?.delegate = self
            tf?.applyFormFieldStyle()
            tf?.setLeftPadding(14)
            tf?.heightAnchor.constraint(equalToConstant: 48).isActive = true
        }

        // ✅ 키보드/입력 옵션
        tfEmail.keyboardType = .emailAddress
        tfEmail.autocapitalizationType = .none
        tfEmail.autocorrectionType = .no

        tfPassword.isSecureTextEntry = true
        tfPasswordConfirm.isSecureTextEntry = true

        tfPhoneMid.keyboardType = .numberPad
        tfPhoneLast.keyboardType = .numberPad
        tfBirth.keyboardType = .numberPad   // (원래 numbersAndPunctuation 쓰고 싶으면 바꿔도 됨)

        // ✅ (선택) 개별 스타일 함수 유지하고 싶으면 그대로
        tfName.styleTextField()
        tfEmail.styleTextField()
        tfPassword.styleTextField()
        tfPasswordConfirm.styleTextField()
        tfBirth.styleTextField()
        tfPhoneMid.styleTextField()
        tfPhoneLast.styleTextField()

        btnPhoneFirst.applyPillStyle()
        btnCity.applyPillStyle()
        btnTown.applyPillStyle()
        btnRole.applyPillStyle()

        btnRegister.layer.cornerRadius = 10

        // ✅ 기본 타이틀 (비어있을 때만 세팅)
        if (btnPhoneFirst.currentTitle ?? "").isEmpty {
            selectedPhoneFirst = "010"
            btnPhoneFirst.setTitle(selectedPhoneFirst, for: .normal)
        } else {
            selectedPhoneFirst = btnPhoneFirst.currentTitle ?? "010"
        }

        if (btnCity.currentTitle ?? "").isEmpty {
            btnCity.setTitle("시/도 선택", for: .normal)
        }
        if (btnTown.currentTitle ?? "").isEmpty {
            btnTown.setTitle("구/군 선택", for: .normal)
        }
        if (btnRole.currentTitle ?? "").isEmpty {
            btnRole.setTitle("사용자구분 선택", for: .normal)
        }

        // ✅ 이메일 상태 라벨 초기화
        emailStatusLabel?.text = ""

        // ✅ 성별 세그먼트 구성
        segGender.removeAllSegments()
        segGender.insertSegment(withTitle: "남", at: 0, animated: false)
        segGender.insertSegment(withTitle: "여", at: 1, animated: false)
        segGender.selectedSegmentIndex = UISegmentedControl.noSegment

        // ✅ 시/도 선택 전엔 구/군 비활성
        resetTownSelectionUI()
    }

    private func setupWatchers() {
        tfEmail.addTarget(self, action: #selector(onEmailChanged), for: .editingChanged)

        // ✅ 생년월일 YYYY-MM-DD 자동 포맷
        tfBirth.addTarget(self, action: #selector(onBirthChanged), for: .editingChanged)

        // ✅ 숫자 키보드 Done toolbar (선택)
        let numberToolbar = makeNumberToolbar()
        tfBirth.inputAccessoryView = numberToolbar
        tfPhoneMid.inputAccessoryView = numberToolbar
        tfPhoneLast.inputAccessoryView = numberToolbar
    }
    @objc private func onBirthChanged() {
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
    private func makeNumberToolbar() -> UIToolbar {
        let bar = UIToolbar()
        bar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(endEditingAll))
        bar.items = [flex, done]
        return bar
    }

    @objc private func onEmailChanged() {
        // email changed -> re-check required
        isEmailChecked = false
        emailStatusLabel?.text = ""
        closeForm()
    }

    private func openForm() { formContainer.isHidden = false }
    private func closeForm() { formContainer.isHidden = true }

    // MARK: - Actions

    /// btnPhoneFirst 선택 (010/011/016/017/018/019)
    @IBAction func pickPhoneFirstTapped(_ sender: UIButton) {
        pickSimple(title: "휴대폰 앞자리 선택", options: phoneFirstOptions, anchor: sender) { [weak self] v in
            self?.btnPhoneFirst.setTitle(v, for: .normal)
        }
    }

    /// 이메일 중복확인 (Android 1:1)
    @IBAction func checkEmailTapped(_ sender: UIButton) {
        let email = trimmed(tfEmail.text)

        guard isValidEmail(email) else {
            toast("유효한 이메일을 입력하세요.")
            return
        }

        Task {
            showLoading(true)
            let res = await service.checkEmailDuplicate(email: email) // SimpleResultResponse?
            showLoading(false)

            guard let res else {
                toast("네트워크 오류 발생")
                isEmailChecked = false
                closeForm()
                return
            }

            let userNo = res.message

            if res.result == true {
                // 신규
                isEmailChecked = true
                emailStatusLabel?.text = "사용 가능한 이메일입니다."
                openForm()
            } else {
                // 기존 -> 소셜 연결
                isEmailChecked = false
                emailStatusLabel?.text = "이미 가입된 이메일입니다. 계정 연결을 진행합니다."
                closeForm()
                await linkSocialAndGoMain(email: email, userNo: userNo)
            }
        }
    }

    /// 기존 회원 -> linkSocial -> 성공 시 Intro 이동
    private func linkSocialAndGoMain(email: String, userNo: String) async {
        let req = LinkSocialRequest(
            userId: email,
            userNo: userNo,
            provider: provider,
            providerUserId: providerUserId
        )

        showLoading(true)
        let body = await service.linkSocial(req) // LoginResponse?
        showLoading(false)

        guard let body else {
            await MainActor.run { self.toast("연결 응답이 비어 있습니다.") }
            return
        }

        await MainActor.run {
            switch body.resultCode {
            case 200:
                LoginInfoUtil.saveLoginInfo(
                    email: body.loginId ?? "",
                    loginNo: body.loginIdx ?? "",
                    password: body.loginPwd ?? "",
                    memberCode: body.memberCode ?? "",
                    loginNm: body.loginNm ?? "",
                    loginCd: body.loginCd ?? "",
                    loginSocialId: body.loginSocialId ?? ""
                )
                self.coordinator?.showIntro(launchDeepLink: self.pendingDeepLink, animated: true)
                self.toast("소셜계정 링크 성공!!!")

            case 409: self.toast("이미 다른 사용자에 연결된 소셜 계정입니다. (409)")
            case 400: self.toast("요청이 올바르지 않습니다. (400)")
            case 601: self.toast("사용자를 찾을 수 없습니다. (601)")
            case 500: self.toast("서버 오류가 발생했습니다. (500)")
            default:  self.toast("연결 실패")
            }
        }
    }

    /// 신규 회원가입 (Android registerUser 1:1) — postOnboarding 미사용
    @IBAction func registerTapped(_ sender: UIButton) {
        let name = trimmed(tfName.text)
        let email = trimmed(tfEmail.text)
        let password = trimmed(tfPassword.text)
        let password2 = trimmed(tfPasswordConfirm.text)

        let phone = "\(trimmed(btnPhoneFirst.currentTitle))-\(trimmed(tfPhoneMid.text))-\(trimmed(tfPhoneLast.text))"
        let birth = trimmed(tfBirth.text)

        let gender: String = {
            switch segGender.selectedSegmentIndex {
            case 0: return "1"
            case 1: return "2"
            default: return ""
            }
        }()

        // Android 검증 그대로
        if name.isEmpty { toast("이름을 입력하세요."); return }
        if !isValidEmail(email) { toast("유효한 이메일을 입력하세요."); return }
        if !isEmailChecked { toast("이메일 중복 확인을 해주세요."); return }
        if password.count < 4 { toast("비밀번호는 최소 4자 이상이어야 합니다."); return }
        if password != password2 { toast("비밀번호 확인이 일치하지 않습니다."); return }
        if birth.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) == nil {
            toast("생년월일은 YYYY-MM-DD 형식으로 입력하세요."); return
        }
        if phone.range(of: #"^01[016789]-\d{3,4}-\d{4}$"#, options: .regularExpression) == nil {
            toast("유효한 전화번호를 입력하세요."); return
        }
        if gender.isEmpty { toast("성별을 선택하세요."); return }
        if selectedCityCode.isEmpty || selectedTownCode.isEmpty { toast("지역을 모두 선택하세요."); return }
        if selectedRoleCode.isEmpty { toast("사용자구분을 선택하세요."); return }

        // Membership DTO(OpUserVO) 그대로
        var user = OpUserVO()
        user.userNm = name
        user.email = email
        user.userId = email
        user.password = password
        user.cttpc = phone
        user.cttpcSeCode = ""         // Membership에 있으면 유지
        user.gender = Int(gender)
        user.userAge = ""
        user.birthDate = birth
        user.areaCode = selectedCityCode
        user.areaSeCodeS = selectedTownCode
        user.areaSeCodeD = ""
        user.referrerId = ""
        user.userSttusCode = "10"
        user.memberCode = selectedRoleCode

        // 소셜 가입 핵심
        user.provider = provider
        user.providerUserId = providerUserId

        Task {
            showLoading(true)
            let res = await service.registerUser(user) // LoginResponse?
            showLoading(false)

            guard let res else {
                toast("네트워크 오류 발생")
                return
            }

            if res.resultCode == 200 {
                LoginInfoUtil.saveLoginInfo(
                    email: res.loginId ?? "",           // login_id
                    loginNo: res.loginIdx ?? "",         // login_idx
                    password: res.loginPwd ?? "",        // login_pwd (서버 응답 기준)
                    memberCode: res.memberCode ?? "",   // member_code
                    loginNm: res.loginNm ?? "",          // login_nm
                    loginCd: res.loginCd ?? "",          // login_cd
                    loginSocialId: res.loginSocialId ?? "" // login_social_id
                )
                coordinator?.showIntro(launchDeepLink: pendingDeepLink, animated: true)
                toast("회원가입 성공!")
            } else {
                toast("회원가입 실패")
            }
        }
    }

    // MARK: - Pickers (Membership 스타일)
    @IBAction func pickCityTapped(_ sender: UIButton) {
        pick(from: cityList, title: "시/도 선택", anchor: sender) { [weak self] item in
            guard let self else { return }
            self.selectedCityCode = item.strIdx
            self.btnCity.setTitle(item.strMsg, for: .normal)

            // reset town
            self.selectedTownCode = ""
            self.btnTown.setTitle("구/군 선택", for: .normal)
            self.resetTownSelectionUI()
            self.loadTownList(cityCode: item.strIdx)
        }
    }

    @IBAction func pickTownTapped(_ sender: UIButton) {
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

    @IBAction func pickRoleTapped(_ sender: UIButton) {
        let options = Array(roleMap.keys)
        pickSimple(title: "사용자구분 선택", options: options, anchor: sender) { [weak self] key in
            guard let self else { return }
            self.selectedRoleCode = self.roleMap[key] ?? ""
            self.btnRole.setTitle(key, for: .normal)
        }
    }

    // MARK: - Code loading (Membership API 사용)
    private func loadCityList() {
        Task {
            do {
                let list = try await service.getCodeList(groupId: "R010070")
                await MainActor.run { self.cityList = list }
            } catch {
                await MainActor.run { self.toast("지역 목록 불러오기 실패") }
            }
        }
    }

    private func loadTownList(cityCode: String) {
        Task {
            do {
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

    // MARK: - Sheet Helpers
    private func pick(from list: [TxtListDataInfo], title: String, anchor: UIView, onPick: @escaping (TxtListDataInfo) -> Void) {
        guard !list.isEmpty else { toast("목록이 없습니다"); return }

        let ac = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        for item in list {
            ac.addAction(UIAlertAction(title: item.strMsg, style: .default) { _ in onPick(item) })
        }
        ac.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = anchor
            pop.sourceRect = anchor.bounds
        }
        present(ac, animated: true)
    }

    private func pickSimple(title: String, options: [String], anchor: UIView, onPick: @escaping (String) -> Void) {
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

    // MARK: - Loading / Toast
    private func showLoading(_ show: Bool) {
        loadingOverlay.isHidden = !show
        if show { loadingSpinner.startAnimating() }
        else { loadingSpinner.stopAnimating() }
    }

    private func toast(_ msg: String) {
        let a = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "확인", style: .default))
        present(a, animated: true)
    }

    // MARK: - Utils
    private func trimmed(_ s: String?) -> String {
        (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isValidEmail(_ s: String) -> Bool {
        let p = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return s.range(of: p, options: .regularExpression) != nil
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingAll))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func endEditingAll() {
        view.endEditing(true)
    }
}
