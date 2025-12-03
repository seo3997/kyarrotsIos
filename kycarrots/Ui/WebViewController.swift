//
//  WebViewController.swift
//  kycarrots
//
//  Created by soo on 12/2/25.
//


import UIKit
import WebKit
import UniformTypeIdentifiers

class WebViewController: UIViewController {
      
    // MARK: - Outlets (스토리보드에서 연결)
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var webView: WKWebView!

    // MARK: - Public properties (Android의 EXTRA_URL, EXTRA_TITLE 역할)
    var initialURLString: String?
    var initialTitle: String?

    // MARK: - Private
    private let refreshControl = UIRefreshControl()
    private var progressObservation: NSKeyValueObservation?
    private var openPanelCompletion: (([URL]?) -> Void)?

    // 기본 URL (Android: Constants.BASE_URL + "front/board/selectPageListBoard.do")
    private let defaultBoardURLString =
        "https://www.your-base-url.com/front/board/selectPageListBoard.do" // TODO: 실제 BASE_URL로 교체

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        addLeftMenuButton()
        setupTitle()
        setupWebView()
        setupRefreshControl()
        observeProgress()

        loadInitialURL()
    }

    deinit {
        progressObservation?.invalidate()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "iOSBridge")
    }

    // MARK: - Setup

    private func setupTitle() {
        // Android: initialTitle ?: "공지사항"
        if let t = initialTitle, !t.isEmpty {
            title = t
        } else {
            title = "공지사항"
        }
    }

    private func setupWebView() {
        // delegate 연결
        webView.navigationDelegate = self
        webView.uiDelegate = self

        // UserAgent (Android: " KyCarrotsApp/Android")
        // iOS 버전은 KyCarrotsApp/iOS
        if #available(iOS 13.0, *) {
            webView.customUserAgent = (webView.customUserAgent ?? "") + " KyCarrotsApp/iOS"
        }

        // JS & 기타 설정
        webView.configuration.preferences.javaScriptEnabled = true
        webView.configuration.websiteDataStore = .default()

        // JS 브리지 등록 (Android: addJavascriptInterface(BoardBridge(), "AndroidBridge"))
        webView.configuration.userContentController.add(self, name: "iOSBridge")
    }

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
    }

    private func observeProgress() {
        // Android: onProgressChanged 와 동일
        progressView.isHidden = true
        progressView.progress = 0

        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
            guard let self = self, let value = change.newValue else { return }
            self.progressView.isHidden = value >= 1.0
            self.progressView.setProgress(Float(value), animated: true)
        }
    }

    private func loadInitialURL() {
        let urlString = initialURLString ?? defaultBoardURLString
        guard let url = URL(string: urlString) else { return }
        let req = URLRequest(url: url)
        webView.load(req)
    }

    // MARK: - Public API (Android: onNewIntent 대체)

    /// 다른 곳에서 이미 띄운 WebViewController에 URL만 바꿔서 다시 쓰고 싶을 때
    func update(urlString: String?, title: String?) {
        if let t = title, !t.isEmpty {
            initialTitle = t
            self.title = t
        }
        if let u = urlString, let url = URL(string: u) {
            webView.load(URLRequest(url: url))
        }
    }

    // MARK: - Actions

    @objc private func onRefresh() {
        webView.reload()
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {

    // Android: shouldOverrideUrlLoading
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url,
              let scheme = url.scheme?.lowercased() else {
            decisionHandler(.allow)
            return
        }

        // tel:, mailto:, sms: 등 외부 스킴 처리
        if scheme == "tel" || scheme == "mailto" || scheme == "sms" {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }

        // intent:// 처럼 특수 스킴
        if url.absoluteString.hasPrefix("intent://") {
            // Android와 완전히 같게는 못하지만, 일단 그냥 열어보는 시도
            if let fallbackURL = URL(string: url.absoluteString.replacingOccurrences(of: "intent://", with: "https://")) {
                UIApplication.shared.open(fallbackURL, options: [:], completionHandler: nil)
            }
            decisionHandler(.cancel)
            return
        }

        // http(s) 이외의 커스텀 스킴 → 외부 앱 시도
        if scheme != "http" && scheme != "https" {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }

        // http, https는 WebView에서 처리
        decisionHandler(.allow)
    }

    // Android: onPageFinished
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        refreshControl.endRefreshing()

        // Android: if (initialTitle == null && !title.isNullOrBlank()) { set title }
        if initialTitle == nil, let pageTitle = webView.title, !pageTitle.isEmpty {
            self.title = pageTitle
        }
    }

    // Android: onReceivedError
    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        refreshControl.endRefreshing()
        showToast("페이지를 불러오지 못했습니다.")
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        refreshControl.endRefreshing()
        showToast("페이지를 불러오지 못했습니다.")
    }

    // 다운로드 비슷하게 처리 (간단버전)
    // HTML 이 아닌 파일 요청을 감지해서 다운로드 시도
    func webView(
        _ webView: WKWebView,
        decidePolicyFor response: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if !response.canShowMIMEType,
           let url = response.response.url {
            // 파일 다운로드 시도
            downloadFile(from: url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    private func downloadFile(from url: URL) {
        // 매우 간단한 예시: Documents 폴더에 저장
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.showToast("다운로드 실패: \(error.localizedDescription)")
                }
                return
            }
            guard let tempURL = tempURL else { return }

            let fileManager = FileManager.default
            let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileName = url.lastPathComponent.isEmpty ? "downloaded_file" : url.lastPathComponent
            let destURL = docs.appendingPathComponent(fileName)

            try? fileManager.removeItem(at: destURL)
            do {
                try fileManager.moveItem(at: tempURL, to: destURL)
                DispatchQueue.main.async {
                    self.showToast("다운로드 완료: \(fileName)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.showToast("파일 저장 실패")
                }
            }
        }
        task.resume()
        showToast("다운로드 시작")
    }
}

// MARK: - WKUIDelegate (파일 선택 <input type=\"file\"> 대응)

extension WebViewController: WKUIDelegate {

    func webView(
        _ webView: WKWebView,
        runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping ([URL]?) -> Void
    ) {
        // Android의 fileChooserCallback 역할
        openPanelCompletion = completionHandler

        let picker: UIDocumentPickerViewController

        if #available(iOS 14.0, *) {
            // 모든 일반 파일 허용 (이미지, 문서, 등등)
            let types: [UTType] = [.data]     // 또는 [.item] 도 가능
            picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        } else {
            // iOS 13 이하 대응
            picker = UIDocumentPickerViewController(
                documentTypes: ["public.data"], // 모든 파일
                in: .import
            )
        }

        picker.delegate = self
        picker.allowsMultipleSelection = parameters.allowsMultipleSelection

        present(picker, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate

extension WebViewController: UIDocumentPickerDelegate {

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        openPanelCompletion?(nil)
        openPanelCompletion = nil
    }

    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        openPanelCompletion?(urls)
        openPanelCompletion = nil
    }
}

// MARK: - JS Bridge (Android: BoardBridge)

extension WebViewController: WKScriptMessageHandler {

    // 웹에서: window.webkit.messageHandlers.iOSBridge.postMessage({ type: "showToast", message: "..." })
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "iOSBridge" else { return }

        if let dict = message.body as? [String: Any] {
            let type = dict["type"] as? String ?? ""
            switch type {
            case "showToast":
                if let msg = dict["message"] as? String {
                    showToast(msg)
                }
            case "refresh":
                webView.reload()
            default:
                break
            }
        } else if let str = message.body as? String {
            // 단순 문자열로 오는 경우
            showToast(str)
        }
    }
}

// MARK: - Helper

extension WebViewController {

    private func showToast(_ message: String) {
        // Snackbar 대체: 간단한 UIAlert
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }

    // Android: companion object start(...) 대응
    static func instantiate(urlString: String? = nil,
                            title: String? = nil) -> WebViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(
            identifier: "WebVC"
        ) as! WebViewController
        vc.initialURLString = urlString
        vc.initialTitle = title
        return vc
    }
}
