//
//  TermsZoomViewController.swift
//  kycarrots
//
//  Created by soo on 1/15/26.
//


import UIKit
import WebKit

final class TermsZoomViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    var screenTitle: String?
    var url: URL?
    var html: String?
    var textZoomPercent: Int = 140

    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = screenTitle ?? "약관 상세보기"

        webView = WKWebView(frame: .zero)
        containerView.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webView.topAnchor.constraint(equalTo: containerView.topAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        webView.navigationDelegate = self
        webView.backgroundColor = .white

        spinner.hidesWhenStopped = true
        spinner.startAnimating()

        if let url {
            webView.load(URLRequest(url: url))
        } else if let html {
            webView.loadHTMLString(html, baseURL: nil)
        } else {
            spinner.stopAnimating()
        }
    }
}

extension TermsZoomViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Android textZoom 적용(간단히 CSS zoom 적용)
        let scale = Double(textZoomPercent) / 100.0
        let js = "document.body.style.zoom = '\(scale)';"
        webView.evaluateJavaScript(js, completionHandler: nil)
        spinner.stopAnimating()
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating()
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating()
    }
}
