import UIKit
import WebKit

final class TermsAgreeViewController: UIViewController, WKNavigationDelegate, UIGestureRecognizerDelegate {

    // MARK: - Outlets (동적인 것만)
    @IBOutlet weak var terms1Container: UIView!
    @IBOutlet weak var terms2Container: UIView!

    @IBOutlet weak var allAgreeButton: UIButton!
    @IBOutlet weak var agree1Button: UIButton!
    @IBOutlet weak var agree2Button: UIButton!

    @IBOutlet weak var joinButton: UIButton!

    // MARK: - State
    private var agreeAll = false
    private var agree1 = false
    private var agree2 = false

    private var webView1: WKWebView!
    private var webView2: WKWebView!

    private var pg1: UIActivityIndicatorView!
    private var pg2: UIActivityIndicatorView!

    // MARK: - URLs (Android와 동일)
    private var terms1Url: String {
        Constants.BASE_URL + "link/join_terms1.do"
    }

    private var terms2Url: String {
        Constants.BASE_URL + "link/join_terms2.do"
    }

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "회원가입"
        setupCheckButton(allAgreeButton, title: "전체 동의")
        setupCheckButton(agree1Button, title: "동의합니다 (필수)")
        setupCheckButton(agree2Button, title: "동의합니다 (필수)")

        updateAllChecks()
        setupTermsWebViews()
        setupProgressViews()
        setupZoomTap()
        terms1Container.applyTermsBoxStyle()
        terms2Container.applyTermsBoxStyle()
        updateJoinEnabled()
        loadTerms()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("nav=", navigationController as Any)
        print("navHidden=", navigationController?.isNavigationBarHidden as Any)
        // ✅ 로그인 화면에서는 메뉴 버튼 자체 없음
        navigationItem.leftBarButtonItem = nil

        // ✅ 스와이프/엣지 제스처로 메뉴 열리는 것도 차단
        navigationController?.view.gestureRecognizers?.forEach { $0.isEnabled = false }
    }

    // MARK: - Check Button
    private func setupCheckButton(_ button: UIButton, title: String) {
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.title = title
            config.image = UIImage(systemName: "square")
            config.imagePadding = 10
            config.baseForegroundColor = .systemGreen
            config.contentInsets = NSDirectionalEdgeInsets(
                top: 8, leading: 0, bottom: 8, trailing: 0
            )
            button.configuration = config
        } else {
            button.setTitle(title, for: .normal)
            button.setImage(UIImage(systemName: "square"), for: .normal)
            button.tintColor = .systemGreen
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        }

        button.contentHorizontalAlignment = .leading
        button.contentHorizontalAlignment = .trailing
        button.adjustsImageWhenHighlighted = false
    }
    private func updateCheck(_ button: UIButton, checked: Bool) {
        let image = UIImage(
            systemName: checked ? "checkmark.square.fill" : "square"
        )

        if #available(iOS 15.0, *) {
            guard var config = button.configuration else { return }
            config.image = image
            button.configuration = config
        } else {
            button.setImage(image, for: .normal)
        }
    }
    private func updateAllChecks() {
        updateCheck(allAgreeButton, checked: agreeAll)
        updateCheck(agree1Button, checked: agree1)
        updateCheck(agree2Button, checked: agree2)
    }

    private func updateJoinEnabled() {
        let enabled = agree1 && agree2
        joinButton.isEnabled = enabled
        joinButton.alpha = enabled ? 1.0 : 0.5
    }

    // MARK: - WebView
    private func setupTermsWebViews() {
        webView1 = makeWebView()
        webView2 = makeWebView()

        embed(webView1, into: terms1Container)
        embed(webView2, into: terms2Container)
    }

    private func makeWebView() -> WKWebView {
        let wv = WKWebView()
        wv.navigationDelegate = self

        // ✅ 스크롤 ON
        wv.scrollView.isScrollEnabled = true
        wv.scrollView.bounces = true

        wv.isOpaque = false
        wv.backgroundColor = .clear
        return wv
    }

    private func embed(_ webView: WKWebView, into container: UIView) {
        container.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.topAnchor.constraint(equalTo: container.topAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    // MARK: - Progress (CODE ONLY)
    private func setupProgressViews() {
        pg1 = makeProgress(in: terms1Container)
        pg2 = makeProgress(in: terms2Container)
    }

    private func makeProgress(in container: UIView) -> UIActivityIndicatorView {
        let pg = UIActivityIndicatorView(style: .medium)
        pg.hidesWhenStopped = true
        pg.stopAnimating()

        container.addSubview(pg)
        pg.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pg.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            pg.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return pg
    }

    // MARK: - Load
    private func loadTerms() {
        if let url1 = URL(string: terms1Url) {
            webView1.load(URLRequest(url: url1))
        }
        if let url2 = URL(string: terms2Url) {
            webView2.load(URLRequest(url: url2))
        }
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if webView === webView1 {
            pg1.startAnimating()
        } else if webView === webView2 {
            pg2.startAnimating()
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView === webView1 {
            pg1.stopAnimating()
        } else if webView === webView2 {
            pg2.stopAnimating()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if webView === webView1 {
            pg1.stopAnimating()
        } else if webView === webView2 {
            pg2.stopAnimating()
        }
    }

    // MARK: - Zoom
    private func setupZoomTap() {
        let wvTap1 = UITapGestureRecognizer(target: self, action: #selector(openTerms1))
        wvTap1.cancelsTouchesInView = false
        wvTap1.delegate = self
        webView1.scrollView.addGestureRecognizer(wvTap1)

        let wvTap2 = UITapGestureRecognizer(target: self, action: #selector(openTerms2))
        wvTap2.cancelsTouchesInView = false
        wvTap2.delegate = self
        webView2.scrollView.addGestureRecognizer(wvTap2)
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    @objc private func openTerms1() {
        print("openTerms1 tapped")
        openZoom(title: "이용약관", url: terms1Url)
    }

    @objc private func openTerms2() {
        print("openTerms2 tapped")
        openZoom(title: "개인정보 수집·이용 동의", url: terms2Url)
    }

    private func openZoom(title: String, url: String) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(
            withIdentifier: "TermsZoomVC"
        ) as? TermsZoomViewController else { return }

        vc.screenTitle = title
        vc.url = URL(string: url)
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Actions
    @IBAction func allAgreeTapped(_ sender: UIButton) {
        agreeAll.toggle()
        agree1 = agreeAll
        agree2 = agreeAll
        updateAllChecks()
        updateJoinEnabled()
    }

    @IBAction func agree1Tapped(_ sender: UIButton) {
        agree1.toggle()
        agreeAll = agree1 && agree2
        updateAllChecks()
        updateJoinEnabled()
    }

    @IBAction func agree2Tapped(_ sender: UIButton) {
        agree2.toggle()
        agreeAll = agree1 && agree2
        updateAllChecks()
        updateJoinEnabled()
    }

    @IBAction func joinTapped(_ sender: UIButton) {
        guard agree1 && agree2 else { return }

        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(
            withIdentifier: "MembershipVC"
        ) as? MembershipViewController else {
            assertionFailure("MembershipVC 캐스팅 실패")
            return
        }

        // ✅ 여기서 주입
        vc.service = AppServiceProvider.shared   // ← 너 프로젝트에 맞는 service

        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func cancelTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}
