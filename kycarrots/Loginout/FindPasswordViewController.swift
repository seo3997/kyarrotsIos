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

             let resultCode = await FindPassword(
                 email: email,
                 service: service
             ).find()

             switch resultCode {

             case StaticDataInfo.RESULT_CODE_ERR:
                 showAlert("통신 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.")

             case StaticDataInfo.RESULT_NO_USER,
                  StaticDataInfo.RESULT_NO_DATA:
                 showAlert("가입된 회원 정보가 없습니다.")

             case StaticDataInfo.RESULT_CODE_200:
                 showAlert(
                     "비밀번호 초기화 안내 메일을\n\(email) 로 전송했습니다."
                 ) { [weak self] in
                     self?.navigationController?.popViewController(animated: true)
                 }

             case StaticDataInfo.RESULT_PWD_ERR:
                 showAlert("비밀번호 처리 중 오류가 발생했습니다.\n관리자에게 문의해주세요.")

             case StaticDataInfo.RESULT_MEMBER_CODE_ERR:
                 showAlert("회원 정보가 올바르지 않습니다.")

             case StaticDataInfo.RESULT_NO_SOCAIL_DATA:
                 showAlert("소셜 로그인 회원은 비밀번호를 변경할 수 없습니다.")

             default:
                 showAlert("알 수 없는 오류가 발생했습니다.")
             }
         }
    }

    private func isValidEmail(_ s: String) -> Bool {
        // 안드로이드 정규식보다 느슨하지만 충분 (원하면 동일 정규식도 가능)
        return s.contains("@") && s.contains(".")
    }
}
