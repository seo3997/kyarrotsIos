//
//  FindAccountViewController.swift
//  kycarrots
//
//  Created by soo on 1/14/26.
//


import UIKit

final class FindAccountViewController: UIViewController {

    @IBOutlet weak var segmented: UISegmentedControl!
    @IBOutlet weak var containerView: UIView!

    // ✅ 주입 받을 서비스 (로그인 화면/코디네이터에서 세팅)
    var service: AppService!

    private var emailVC: FindEmailViewController!
    private var pwdVC: FindPasswordViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "아이디 / 비밀번호 찾기"
        print("FindAccount storyboard = \(String(describing: storyboard))")
        print("containerView is nil? \(containerView == nil)")
        print("segmented is nil? \(segmented == nil)")
        
        // child VC instantiate
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard
          let emailVC = sb.instantiateViewController(withIdentifier: "FindEmailVC") as? FindEmailViewController,
          let pwdVC   = sb.instantiateViewController(withIdentifier: "FindPasswordVC") as? FindPasswordViewController
        else {
          assertionFailure("FindEmailVC / FindPasswordVC not found")
          return
        }

        emailVC.service = service
        pwdVC.service = service
        
        self.emailVC = emailVC
        self.pwdVC = pwdVC
        
        segmented.selectedSegmentIndex = 0
        switchTab(0)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // ✅ 로그인 화면에서는 메뉴 버튼 자체 없음
        navigationItem.leftBarButtonItem = nil

        // ✅ 스와이프/엣지 제스처로 메뉴 열리는 것도 차단
        navigationController?.view.gestureRecognizers?.forEach { $0.isEnabled = false }
    }
    
    @IBAction func onSegmentChanged(_ sender: UISegmentedControl) {
        switchTab(sender.selectedSegmentIndex)
    }

    private func switchTab(_ idx: Int) {
        let target = (idx == 0) ? emailVC! : pwdVC!
        setChild(target)
    }

    private func setChild(_ vc: UIViewController) {
        // remove existing
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }

        addChild(vc)
        vc.view.frame = containerView.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(vc.view)
        vc.didMove(toParent: self)
    }
}
