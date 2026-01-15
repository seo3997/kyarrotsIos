//
//  FindPasswordViewController.swift
//  kycarrots
//
//  Created by soo on 1/14/26.
//


import UIKit

final class FindPasswordViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var findButton: UIButton!

    var service: AppService!

    private let loader = BlockingLoader()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 키보드 / 입력 속성 (기존 로직 유지)
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no

        // ✅ 공통 입력 필드 스타일
        emailField.delegate = self
        emailField.applyFormFieldStyle()
        emailField.setLeftPadding(14)
        emailField.heightAnchor.constraint(equalToConstant: 48).isActive = true

        // ✅ CTA 버튼 (강조 버튼은 기존 스타일 유지)
        findButton.layer.cornerRadius = 10
    }

    @IBAction func onFindPassword(_ sender: UIButton) {
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !email.isEmpty else { return showAlert("이메일을 입력해 주세요.") }
        guard isValidEmail(email) else { return showAlert("이메일 형식이 올바르지 않습니다.") }

        Task { @MainActor in
            loader.show(on: view)
            defer { loader.hide() }

            let result = await service.findPassword(email: email)

            if let msg = result, !msg.isEmpty {
                showAlert(msg) { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            } else {
                showAlert("가입 정보가 없습니다.")
            }
        }
    }

    private func isValidEmail(_ s: String) -> Bool {
        // 안드로이드 정규식보다 느슨하지만 충분 (원하면 동일 정규식도 가능)
        return s.contains("@") && s.contains(".")
    }
}
