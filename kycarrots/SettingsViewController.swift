import UIKit

final class SettingsViewController: UIViewController {

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let content = UIStackView()

    // 프로필
    private let profileImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "person.crop.circle"))
        iv.contentMode = .scaleAspectFill
        iv.tintColor = .secondaryLabel
        iv.backgroundColor = .secondarySystemBackground
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let userIdLabel    = SettingsViewController.makeInfoLabel(prefix: "아이디: ")
    private let userNameLabel  = SettingsViewController.makeInfoLabel(prefix: "이름: ")
    private let userTelLabel   = SettingsViewController.makeInfoLabel(prefix: "연락처: ")
    private let userAddrLabel  = SettingsViewController.makeInfoLabel(prefix: "주소: ")

    // 태그 영역
    private let tagsHStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .leading
        s.distribution = .fillProportionally
        return s
    }()

    // 구분선
    private static func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([ v.heightAnchor.constraint(equalToConstant: 1) ])
        return v
    }

    // 섹션 타이틀
    private static func makeSectionTitle(_ text: String) -> UILabel {
        let lb = UILabel()
        lb.text = text
        lb.font = .boldSystemFont(ofSize: 16)
        return lb
    }

    // 스위치 행
    private let pushRow = SettingsSwitchRow(title: "푸시 알림", isOn: true)

    // 버튼
    private let changePasswordButton: UIButton = {
        var conf = UIButton.Configuration.plain()
        conf.title = "비밀번호 변경"
        conf.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        let b = UIButton(configuration: conf)
        b.contentHorizontalAlignment = .leading
        return b
    }()

    private let logoutButton: UIButton = {
        var conf = UIButton.Configuration.filled()
        conf.title = "로그아웃"
        let b = UIButton(configuration: conf)
        b.configuration?.baseBackgroundColor = .systemRed
        b.configuration?.baseForegroundColor = .white
        b.contentHorizontalAlignment = .center
        return b
    }()

    // MARK: - Life
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "프로필 / 설정"
        view.backgroundColor = .systemBackground
        setupLayout()
        setupActions()
        loadDemoData()
    }

    // MARK: - Layout
    private func setupLayout() {
        // 네비게이션 바 뒤로가기 버튼은 상위 VC에서 자동 제공(혹은 아래 라인으로 수동 아이템)
        // navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(tapBack))

        // Scroll + content
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        content.axis = .vertical
        content.spacing = 12
        content.alignment = .fill
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 24, trailing: 16)

        scrollView.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        ])

        // 프로필 이미지 (원형)
        let profileContainer = UIView()
        profileContainer.addSubview(profileImageView)
        NSLayoutConstraint.activate([
            profileImageView.centerXAnchor.constraint(equalTo: profileContainer.centerXAnchor),
            profileImageView.topAnchor.constraint(equalTo: profileContainer.topAnchor),
            profileImageView.bottomAnchor.constraint(equalTo: profileContainer.bottomAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 80),
            profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor)
        ])
        content.addArrangedSubview(profileContainer)
        profileImageView.layer.cornerRadius = 40

        // 사용자 정보 라벨들
        let infoStack = UIStackView(arrangedSubviews: [userIdLabel, userNameLabel, userTelLabel, userAddrLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 6
        content.addArrangedSubview(infoStack)

        // 태그 (예: 상추, 배추)
        content.addArrangedSubview(tagsHStack)
        addTag("상추")
        addTag("배추")

        // 구분선
        content.addArrangedSubview(Self.makeDivider())

        // 섹션 타이틀
        content.addArrangedSubview(Self.makeSectionTitle("앱 설정"))

        // 푸시 스위치
        content.addArrangedSubview(pushRow)

        // 비밀번호 변경
        content.addArrangedSubview(changePasswordButton)

        // 여백
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([ spacer.heightAnchor.constraint(equalToConstant: 8) ])
        content.addArrangedSubview(spacer)

        // 로그아웃 버튼
        content.addArrangedSubview(logoutButton)
    }

    private func setupActions() {
        pushRow.onToggle = { [weak self] isOn in
            // TODO: 서버/로컬 설정 반영
            print("푸시 알림:", isOn ? "ON" : "OFF")
            self?.showToast(isOn ? "푸시 알림이 켜졌습니다." : "푸시 알림이 꺼졌습니다.")
        }
        changePasswordButton.addTarget(self, action: #selector(tapChangePassword), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(tapLogout), for: .touchUpInside)
    }

    private func loadDemoData() {
        // 데모 데이터 (실제 데이터 바인딩 지점)
        userIdLabel.text   = "아이디: soohyoun"
        userNameLabel.text = "이름: 서수현"
        userTelLabel.text  = "연락처: 010-1234-5678"
        userAddrLabel.text = "주소: 경기도 수원시 팔달구 …"
    }

    // MARK: - Actions
    @objc private func tapChangePassword() {
        // TODO: 실제 비밀번호 변경 화면 push/present
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        vc.title = "비밀번호 변경"
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func tapLogout() {
        // TODO: 실제 로그아웃 로직(토큰 삭제, 초기화면 이동 등)
        let alert = UIAlertController(title: "로그아웃", message: "정말 로그아웃 하시겠어요?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive, handler: { _ in
            print("로그아웃 처리")
            self.navigationController?.popToRootViewController(animated: true)
        }))
        present(alert, animated: true)
    }

    private func addTag(_ text: String) {
        let tag = PaddingLabel()
        tag.text = text
        tag.font = .systemFont(ofSize: 13, weight: .medium)
        tag.textColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.systemTeal : UIColor.systemTeal
        }
        tag.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.systemTeal.withAlphaComponent(0.15)
                                              : UIColor.systemTeal.withAlphaComponent(0.15)
        }
        tag.layer.cornerRadius = 6
        tag.clipsToBounds = true
        tag.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        tagsHStack.addArrangedSubview(tag)
    }

    private func showToast(_ message: String) {
        let lb = UILabel()
        lb.text = message
        lb.textColor = .white
        lb.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        lb.textAlignment = .center
        lb.numberOfLines = 0
        lb.layer.cornerRadius = 10
        lb.clipsToBounds = true
        lb.alpha = 0
        lb.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(lb)
        NSLayoutConstraint.activate([
            lb.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            lb.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            lb.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        UIView.animate(withDuration: 0.25, animations: { lb.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.25, delay: 1.2, options: [], animations: {
                lb.alpha = 0
            }, completion: { _ in lb.removeFromSuperview() })
        }
    }

    @objc private func tapBack() {
        navigationController?.popViewController(animated: true)
    }

    // Info label 팩토리
    private static func makeInfoLabel(prefix: String) -> UILabel {
        let lb = UILabel()
        lb.text = prefix
        lb.font = .systemFont(ofSize: 15)
        lb.textAlignment = .left
        return lb
    }
}

// MARK: - 커스텀 컴포넌트

/// 좌측 타이틀 + 우측 UISwitch 로 구성된 한 줄
final class SettingsSwitchRow: UIView {
    private let titleLabel = UILabel()
    private let switcher = UISwitch()
    var onToggle: ((Bool) -> Void)?

    init(title: String, isOn: Bool) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17)
        switcher.isOn = isOn

        let h = UIStackView(arrangedSubviews: [titleLabel, UIView(), switcher])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 8

        let wrapper = UIStackView(arrangedSubviews: [h])
        wrapper.axis = .vertical
        wrapper.isLayoutMarginsRelativeArrangement = true
        wrapper.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)

        addSubview(wrapper)
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrapper.topAnchor.constraint(equalTo: topAnchor),
            wrapper.leadingAnchor.constraint(equalTo: leadingAnchor),
            wrapper.trailingAnchor.constraint(equalTo: trailingAnchor),
            wrapper.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])

        switcher.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
    }

    @objc private func toggleChanged() { onToggle?(switcher.isOn) }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// 패딩 가능한 라벨
final class PaddingLabel: UILabel {
    var contentInsets = NSDirectionalEdgeInsets.zero
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: contentInsets.top,
                                  left: contentInsets.leading,
                                  bottom: contentInsets.bottom,
                                  right: contentInsets.trailing)
        super.drawText(in: rect.inset(by: insets))
    }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + contentInsets.leading + contentInsets.trailing,
                      height: s.height + contentInsets.top + contentInsets.bottom)
    }
}
