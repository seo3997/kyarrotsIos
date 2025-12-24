//
//  MainTabBarController.swift
//  kycarrots
//
//  Created by soo on 12/24/25.
//


import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLeftMenuButton()
        title = "상품리스트"
        // 1. 탭바 아이템 설정 (아이콘, 타이틀)
        applyFinalTabBarDesign()
        
        self.delegate = self
    }
    
    private func applyFinalTabBarDesign() {
        // 1. 탭바 아이템들이 가로로 최대한 펼쳐지게 설정
        self.tabBar.itemPositioning = .fill
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white // 배경을 흰색으로 고정하여 깔끔하게
        
        // 2. 폰트 설정 (가독성을 위해 크기를 12pt로 키우고 굵게 설정)
        let font = UIFont.systemFont(ofSize: 12, weight: .bold)
        
        // 3. 아이콘과 글자 사이의 간격 및 배치 세부 조정
        // Normal 상태 (비활성)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: font,
            .foregroundColor: UIColor.systemGray
        ]
        // 글자를 아래로 살짝 내려서 아이콘과 안 겹치게 조정 (양수값 = 아래로 이동)
        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2)
        
        // Selected 상태 (활성)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: font,
            .foregroundColor: UIColor.systemBlue
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2)
        
        // 4. 적용
        self.tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            self.tabBar.scrollEdgeAppearance = appearance
        }
        
        // 5. 아이콘 크기가 너무 커서 꽉 안 차 보일 경우를 대비한 세부 설정
        if let items = self.tabBar.items {
            for item in items {
                // 아이콘을 위로 살짝 올려서 글자와의 공간 확보 (음수값 = 위로 이동)
                item.imageInsets = UIEdgeInsets(top: -2, left: 0, bottom: 2, right: 0)
            }
        }
    }
}

// 탭 선택 이벤트를 감지하고 싶을 때 확장
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // 특정 탭이 선택되었을 때 실행할 로직 (예: 진동 피드백 등)
        print("Selected tab: \(tabBarController.selectedIndex)")
    }
}
