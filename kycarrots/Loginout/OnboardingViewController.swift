//
//  OnboardingViewController.swift
//  kycarrots
//
//  Created by soo on 1/20/26.
//


import UIKit

final class OnboardingViewController: UIViewController {

    // MARK: - Injected
    var service: AppService!                 // AppServiceProvider.shared 주입
    weak var coordinator: AppCoordinator?
    var pendingDeepLink: PushDeepLink?

    // Android intent extras 대응
    var provider: String = "KAKAO"           // KAKAO / NAVER / GOOGLE / APPLE
    var providerUserId: String = ""          // 소셜 userId
    var presetEmail: String = ""
    var presetNickname: String = ""

    // MARK: - Email section
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var checkEmailButton: UIButton!
    @IBOutlet weak var emailStatusLabel: UILabel!

    // MARK: - Form container (Membership와 동일)
    @IBOutlet weak var formContainer: UIView!
    @IBOutlet weak var nicknameField: UITextField!

    @IBOutlet weak var btnCity: UIButton!
    @IBOutlet weak var btnTown: UIButton!
    @IBOutlet weak var btnRole: UIButton!

    @IBOutlet weak var marketingPushSwitch: UISwitch!
    @IBOutlet weak var marketingEmailSwitch: UISwitch!
    @IBOutlet weak var tosAgreedSwitch: UISwitch!
    @IBOutlet weak var privacyAgreedSwitch: UISwitch!

    @IBOutlet weak var submitButton: UIButton!

    // MARK: - State
    private var isEmailChecked = false
    private var isNewEmail = false

    // 지역 / 역할 상태 (Membership와 동일)
    private var cityList: [TxtListDataInfo] = []
    private var townList: [TxtListDataInfo] = []

    private var selectedCityCode = ""
    private var selectedTownCode = ""
    private var selectedRoleCode = ""

    private lazy var roleMap: [String: String] = {
        if Constants.SYSTEM_TYPE == 1 {
            return ["판매자":"ROLE_SELL", "구매자":"ROLE_PUB"]
        } else {
            return ["판매자":"ROLE_SELL", "센터관리":"ROLE_PROJ", "구매자":"ROLE_PUB"]
        }
    }()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(service != nil, "OnboardingViewController.service 주입 필요")

        title = "온보딩"
        setupUI()
        bindPreset()
        resetInitialState()

        emailField.addTarget(self, action: #selector(onEmailChanged), for: .editingChanged)

        resetTownSelectionUI()
        loadCityList()
    }

    // MARK: - UI Setup
    private func setupUI() {
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no

        checkEmailButton.layer.cornerRadius = 10
        submitButton.layer.cornerRadius = 12

        emailStatusLabel.text = ""
        formContainer.isHidden = true
        submitButton.isEnabled = false
    }

    private func bindPreset() {
        emailField.text = presetEmail
        nicknameField.text = presetNickname
    }

    private func resetInitialState() {
        isEmailChecked = false
        isNewEmail = false
        formContainer.isHidden = true
        submitButton.isEnabled = false
        emailStatusLabel.text = ""
    }

    @objc private func onEmailChanged() {
        resetInitialState()
    }

    private func openFullOnboarding() {
        formContainer.isHidden = false
        submitButton.isEnabled = true
    }

    // MARK: - Actions

    /// Android checkEmailDuplicate()와 동일
    @IBAction func checkEmailTapped(_ sender: UIButton) {
        let email = emailField.text?.trimmed ?? ""

        guard isValidEmail(email) else {
            toast("유효한 이메일을 입력하세요.")
            return
        }

        Task {
            showLoading(true)
            guard let response = await service.checkEmailDuplicate(email: email) else {
                    showLoading(false)
                    toast("이메일 확인 응답이 없습니다.")
                    return
                }
            showLoading(false)
            isEmailChecked = true
            let userNo = response.message
            if response.result {
                // 신규
                emailStatusLabel.text = "사용 가능한 이메일입니다."
                openFullOnboarding()
            } else {
                // 기존 회원 → 소셜 연결
                emailStatusLabel.text = "이미 가입된 이메일입니다. 계정 연결을 진행합니다."
                await linkSocialAndGoMain(email: email, userNo: userNo)
            }
        }
    }

    /// 기존 회원 → linkSocial → 메인 이동 (Android 1:1)
    private func linkSocialAndGoMain(email: String, userNo: String) async {
        let req = LinkSocialRequest(
            userId: email,
            userNo: userNo,
            provider: provider,
            providerUserId: providerUserId
        )

        guard let body = await service.linkSocial(req) else {
            toast("연결 응답이 비어 있습니다.")
            return
        }

        switch body.resultCode {
        case 200:
            LoginInfoUtil.saveLoginInfo(
                email: body.loginId ?? email,
                loginNo: body.loginIdx ?? "",
                password: body.loginPwd ?? "",
                memberCode: body.memberCode ?? "",
                loginNm: body.loginNm ?? "",
                loginCd: body.loginCd ?? provider,
                loginSocialId: body.loginSocialId ?? providerUserId
            )
            coordinator?.showIntro(
                launchDeepLink: pendingDeepLink,
                animated: true
            )

        case 409:
            toast("이미 다른 사용자에 연결된 소셜 계정입니다.")
        case 400:
            toast("요청이 올바르지 않습니다.")
        case 601:
            toast("사용자를 찾을 수 없습니다.")
        case 500:
            toast("서버 오류가 발생했습니다.")
        default:
            toast("연결 실패")
        }
    }

    /// 신규 회원 → postOnboarding
    @IBAction func submitTapped(_ sender: UIButton) {
        guard isEmailChecked, isNewEmail else {
            toast("이메일 확인 후 진행하세요.")
            return
        }

        guard tosAgreedSwitch.isOn, privacyAgreedSwitch.isOn else {
            toast("필수 약관 동의가 필요합니다.")
            return
        }

        let req = OnboardingRequest(
            nickname: nicknameField.text ?? "",
            email: emailField.text ?? "",
            role: selectedRoleCode,
            areaGroup: selectedCityCode,
            areaMid: selectedTownCode,
            areaScls: nil,
            marketingPush: marketingPushSwitch.isOn,
            marketingEmail: marketingEmailSwitch.isOn,
            tosAgreed: tosAgreedSwitch.isOn,
            privacyAgreed: privacyAgreedSwitch.isOn
        )

        Task {
            showLoading(true)
            let res = await service.postOnboarding(req)
            showLoading(false)

            if res != nil {
                coordinator?.showIntro(
                    launchDeepLink: pendingDeepLink,
                    animated: true
                )
            } else {
                toast("회원가입 실패")
            }
        }
    }

    // MARK: - City / Town / Role (Membership와 동일)

    @IBAction func pickCityTapped(_ sender: UIButton) {
        pick(from: cityList, title: "시/도 선택", anchor: sender) { item in
            self.selectedCityCode = item.strIdx
            self.btnCity.setTitle(item.strMsg, for: .normal)

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
        pick(from: townList, title: "구/군 선택", anchor: sender) { item in
            self.selectedTownCode = item.strIdx
            self.btnTown.setTitle(item.strMsg, for: .normal)
        }
    }

    @IBAction func pickRoleTapped(_ sender: UIButton) {
        let keys = Array(roleMap.keys)
        pickSimple(title: "사용자구분 선택", options: keys, anchor: sender) { key in
            self.selectedRoleCode = self.roleMap[key] ?? ""
            self.btnRole.setTitle(key, for: .normal)
        }
    }

    // MARK: - Code loading (Membership와 동일)

    private func loadCityList() {
        Task {
            do {
                let list = try await service.getCodeList(groupId: "R010070")
                self.cityList = list
            } catch {
                toast("지역 목록 불러오기 실패")
            }
        }
    }

    private func loadTownList(cityCode: String) {
        Task {
            do {
                let list = try await service.getSCodeList(groupId: "R010070", mcode: cityCode)
                self.townList = list
                btnTown.isEnabled = true
                btnTown.alpha = 1.0
            } catch {
                toast("지역 목록 불러오기 실패")
            }
        }
    }

    private func resetTownSelectionUI() {
        btnTown.isEnabled = false
        btnTown.alpha = 0.6
        townList = []
    }

    // MARK: - Picker helpers (Membership와 동일)

    private func pick(from list: [TxtListDataInfo],
                      title: String,
                      anchor: UIView,
                      onPick: @escaping (TxtListDataInfo) -> Void) {
        guard !list.isEmpty else { toast("목록이 없습니다."); return }

        let ac = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        for item in list {
            ac.addAction(UIAlertAction(title: item.strMsg, style: .default) { _ in onPick(item) })
        }
        ac.addAction(UIAlertAction(title: "취소", style: .cancel))
        presentSheet(ac, anchor)
    }

    private func pickSimple(title: String,
                            options: [String],
                            anchor: UIView,
                            onPick: @escaping (String) -> Void) {
        let ac = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        for v in options {
            ac.addAction(UIAlertAction(title: v, style: .default) { _ in onPick(v) })
        }
        ac.addAction(UIAlertAction(title: "취소", style: .cancel))
        presentSheet(ac, anchor)
    }

    private func presentSheet(_ ac: UIAlertController, _ anchor: UIView) {
        if let pop = ac.popoverPresentationController {
            pop.sourceView = anchor
            pop.sourceRect = anchor.bounds
        }
        present(ac, animated: true)
    }

    // MARK: - Utils

    private func isValidEmail(_ s: String) -> Bool {
        s.contains("@") && s.contains(".")
    }

    private func showLoading(_ show: Bool) {
        // 기존 로딩 UI 연결
    }

    private func toast(_ msg: String) {
        let a = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "확인", style: .default))
        present(a, animated: true)
    }
}

// MARK: - String helper
private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
