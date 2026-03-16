1. SettingsView 변경
   서버프로그램,안드로이드 앱은 이미 구현 되어 있어니 동일한 기능으로 구현하다.
   1-1 안드로이드 화면
   com.whomade.kycarrots.setting를 참조,서버프로그램 호출은 동일하게 구현
   SettingActivity.kr, activity_setting.xml을 참조한다.
   1-2 프로필 이미지 변경시 로컬에만 저장한다.
   1-3 사용자정보수정:이름,연락처,주소 변경
   1-4 푸시알림 설정 push는 전송되면 알림 메시지나,진동안 되지 않게 구현
   1-4 비밀번호 변경 기존비밀번화,새로운 비밀번호, 새로운비밀번호 입력후 변경 버튼 실행
   1-5 로그아웃 이미 구현 되어 있음

2. 사용자 상품리스트 swiftUi 로 변경
   목표: 기존 UIKit 기반의 MainTabBarController 및 하위 뷰컨트롤러 3종을 SwiftUI로 완전 교체.
   대상 파일:
   MainTabBarController.swift (삭제 예정)
   HomeViewController.swift → HomeView.swift
   InterestProductViewController.swift → InterestProductView.swift
   PurchaseHistoryViewController.swift → PurchaseHistoryView.swift
   참조: UI 레이아웃 및 컴포넌트 구성은 기존 Main.storyboard의 디자인을 계승함.

2-1 기술 요구 사항 및 구조
파일 배치: 모든 신규 SwiftUI 파일은 /SwiftUI_Views/buy/ 폴더 내에 위치시킨다.
아키텍처:
각 뷰는 독립적인 SwiftUI View로 구현한다.
데이터 바인딩이 필요한 경우 ObservableObject 패턴을 사용하여 비즈니스 로직과 UI를 분리한다.
내비게이션:
MainTabBarController를 대체할 MainTabView.swift를 생성한다.
TabView를 사용하여 하단 탭바를 구성하며, 각 탭은 위에서 정의한 3개의 SwiftUI 뷰를 호출한다.

2-2 세부 구현 가이드
HomeView: 상품 리스트 형식을 List 또는 LazyVGrid를 사용하여 구현하고, 스토리보드에 정의된 상단 배너 및 카테고리 영역을 반영한다.
InterestProductView: 사용자가 '찜'한 상품 리스트를 그리드 형태로 표현한다.
PurchaseHistoryView: 구매 내역 섹션을 날짜별 또는 상태별로 구분하여 리스트 형태로 구현한다.
UIKit 호환성: 필요한 경우 UIHostingController를 사용하여 기존 UIKit 코드와의 접점을 관리하되, 최종적으로는 SwiftUI 중심의 전환을 목표로 한다.

2-3 정리된 파일 리스트 (Target Files)
원본 UIKit 파일,신규 SwiftUI 파일 (경로: /SwiftUI_Views/buy/)
MainTabBarController.swift,MainTabView.swift (TabView 구현)
HomeViewController.swift,HomeView.swift
InterestProductViewController.swift,InterestProductView.swift
PurchaseHistoryViewController.swift,PurchaseHistoryView.swift
