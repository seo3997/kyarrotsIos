import UIKit
import Network
import UserNotifications

final class IntroViewController: UIViewController {

    private let service: AppService
    private weak var coordinator: AppCoordinator?
    private let launchDeepLink: PushDeepLink?

    // ✅ UI (전부 코드)
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "farm_intro")) // ← Assets 이름
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.25) // 어두운 오버레이(가독성)
        return v
    }()

    private let spinner: UIActivityIndicatorView = {
        let sp = UIActivityIndicatorView(style: .large)
        sp.color = .white
        sp.hidesWhenStopped = true
        return sp
    }()

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "net.monitor")
    private var didStart = false

    init(service: AppService, coordinator: AppCoordinator, launchDeepLink: PushDeepLink?) {
        self.service = service
        self.coordinator = coordinator
        self.launchDeepLink = launchDeepLink
        super.init(nibName: nil, bundle: nil)
    }

    // ✅ 스토리보드 생성 금지
    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didStart else { return }
        didStart = true

        spinner.startAnimating()
        startFlow()
    }

    private func buildUI() {
        view.backgroundColor = .black

        [backgroundImageView, dimView, spinner].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            // 배경 이미지 풀스크린
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // 오버레이 풀스크린
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // 스피너 중앙
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func startFlow() {
        checkNetwork { [weak self] ok in
            guard let self else { return }
            guard ok else { self.showNetworkAlert(); return }

            self.requestNotificationPermissionIfNeeded { _ in
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                Task { [weak self] in
                    await self?.autoLoginOrGoLogin()
                }
            }
        }
    }

    private func checkNetwork(completion: @escaping (Bool) -> Void) {
        monitor.pathUpdateHandler = { [weak self] path in
            completion(path.status == .satisfied)
            self?.monitor.cancel()
        }
        monitor.start(queue: monitorQueue)
    }

    private func showNetworkAlert() {
        let alert = UIAlertController(
            title: "네트워크 오류",
            message: "인터넷 연결을 확인해 주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "재시도", style: .default) { [weak self] _ in
            self?.startFlow()
        })
        present(alert, animated: true)
    }

    private func requestNotificationPermissionIfNeeded(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    completion(granted)
                }
            @unknown default:
                completion(false)
            }
        }
    }

    @MainActor
    private func autoLoginOrGoLogin() async {
        if !LoginInfoUtil.isLoggedIn() {
            coordinator?.showLogin(pendingDeepLink: launchDeepLink)
            return
        }

        let userNo = LoginInfoUtil.getUserNo()
        let userId = LoginInfoUtil.getUserId()
        let password = LoginInfoUtil.getUserPassword()
        let loginCd = LoginInfoUtil.getUserLoginCd()
        let socialId = LoginInfoUtil.getUserSocialId()
        let memberCodeHint = LoginInfoUtil.getMemberCode()

        let regId = PushRegIdUtil.getRegId()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

        let res = await service.login(
            email: userId,
            password: password,
            loginCd: loginCd,
            regId: regId,
            appVersion: appVersion,
            providerUserId: socialId
        )

        guard let res else {
            coordinator?.showLogin(pendingDeepLink: launchDeepLink)
            return
        }

        if let token = res.token, !token.isEmpty {
            TokenUtil.saveToken(token)
        }

        if !regId.isEmpty {
            let req = PushTokenVo(
                userNo: userNo,
                userId: userId,
                pushToken: regId,
                deviceType: "iOS"
            )
            _ = await service.savePushToken(req)
        }

        let finalMemberCode = (res.memberCode?.isEmpty == false) ? res.memberCode! : memberCodeHint
        coordinator?.showHome(memberCode: finalMemberCode, deepLink: launchDeepLink)
    }
}
