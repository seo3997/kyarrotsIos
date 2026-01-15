//
//  FindEmailViewController.swift
//  kycarrots
//
//  Created by soo on 1/14/26.
//


import UIKit

final class FindEmailViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var firstNumButton: UIButton!
    @IBOutlet weak var midNumField: UITextField!
    @IBOutlet weak var lastNumField: UITextField!
    @IBOutlet weak var findButton: UIButton!

    var service: AppService!

    private let loader = BlockingLoader()
    private var firstNum: String = "010" {
        didSet { firstNumButton.setTitle(firstNum, for: .normal) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 기본값
        firstNumButton.setTitle(firstNum, for: .normal)

        // 키보드
        midNumField.keyboardType = .numberPad
        lastNumField.keyboardType = .numberPad

        // 입력 제한 로직 (기존 그대로)
        midNumField.addTarget(self, action: #selector(limitMid), for: .editingChanged)
        lastNumField.addTarget(self, action: #selector(limitLast), for: .editingChanged)

        // ✅ 공통 입력 필드 스타일 적용
        [
            nameField,
            midNumField,
            lastNumField
        ].forEach { tf in
            tf?.delegate = self
            tf?.applyFormFieldStyle()
            tf?.setLeftPadding(14)
            tf?.heightAnchor.constraint(equalToConstant: 48).isActive = true
        }

        // ✅ 010 버튼도 입력필드처럼
        firstNumButton.applyFormFieldStyle()
        firstNumButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        firstNumButton.heightAnchor.constraint(equalToConstant: 48).isActive = true

        // CTA 버튼은 강조 스타일 유지
        findButton.layer.cornerRadius = 10
    }

    @IBAction func onPickFirstNum(_ sender: UIButton) {
        let options = ["010", "011", "016", "017", "018", "019"]

        let sheet = UIAlertController(title: "휴대폰 앞자리", message: nil, preferredStyle: .actionSheet)
        options.forEach { opt in
            sheet.addAction(UIAlertAction(title: opt, style: .default) { _ in
                self.firstNum = opt
            })
        }
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))

        // iPad 대응
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }

        present(sheet, animated: true)
    }

    @IBAction func onFindEmail(_ sender: UIButton) {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let mid  = (midNumField.text ?? "").filter { $0.isNumber }
        let last = (lastNumField.text ?? "").filter { $0.isNumber }

        guard !name.isEmpty else { return showAlert("이름을 입력해 주세요.") }
        guard !mid.isEmpty && !last.isEmpty else { return showAlert("휴대폰 번호를 입력해 주세요.") }

        let phone = "\(firstNum)-\(mid)-\(last)"

        Task { @MainActor in
            loader.show(on: view)
            defer { loader.hide() }

            let result = await service.findEmail(name: name, phone: phone)

            if let msg = result, !msg.isEmpty {
                // ✅ 안드로이드: 성공 다이얼로그 후 finish()
                showAlert(msg) { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            } else {
                showAlert("가입된 이메일이 없습니다.")
            }
        }
    }

    @objc private func limitMid() {
        if let t = midNumField.text, t.count > 4 { midNumField.text = String(t.prefix(4)) }
    }

    @objc private func limitLast() {
        if let t = lastNumField.text, t.count > 4 { lastNumField.text = String(t.prefix(4)) }
    }
}
