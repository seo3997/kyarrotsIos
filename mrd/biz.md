1. 안드로이드 앱과 동일한 기능으로 구현
   1.1 구매자 상품리스트
   안드로이드 화면을 참조하여 동일한 기능으로 및 디자인을 구현한다.
   ex) HomeFragment 카테고리, 세부항목, 도시선택, 사구선택 조호조건 삭제
   상품리스트 안드로이드 상품리스트와 동일하게 구현
   buy/HomeView.swift. = HomeFragment.kt
   buy/InterestProductView.swift = InterestProductFragment.kt
   buy/PurchaseHistoryView.swift = PurchaseHistoryFragment.kt
   buy/MainTabView.swift = MainTabBarController.swift

2. 상품상세
   2.1 상품상세 화면
   안드로이드 화면을 참조하여 동일한 기능으로 및 디자인을 구현한다.
   상품상세,상품리뷰,상품문의탭 추가됨
   2-1-1 상품상세
   ProductDescriptionFragment.kt
   2-1-2 상품리뷰
   ProductReviewFragment.kt
   2-1-3 상품문의
   ProductQAFragment.kt
3. 구매하기
   3-1 구매하기 화면
   /Users/soo/Kycarrots/src/main/resources/mrd/order_biz.md 와
   /Users/soo/Kycarrots/src/main/resources/mrd/payment_biz.md 를 참조하고 이미 서버,안드로이드
   구현 되어 있어니 안드로이이 앱을 참고 해서 구현한다.
   iOs 신규화면
   안드로이드 화면을 참조하여 동일한 기능으로 및 디자인을 구현한다.
   구매화면: OrderActivity.kt (배송지 관리 기능 추가)
   구매상세화면: OrderDetailActivity.kt
   주소검새: AddressSearchActivity.kt
   결제화면: PaymentWebViewActivity(결제시 로그인정보의 토스페이먼트 clientKey 전달)
   구매완료화면: OrderSuccessActivity.kt
4. 관리자 주문관리 메뉴 추가
   iOs 신규화면
   로그인권한이 ROLE_SELL,ROLE_PROJ 인경우만 노출
   주문관리:OrderMgtActivity.kt
   구매상세:OrderMgtDetailActivity.kt

5. 대시보드
   대시보드 화면
   안드로이드 화면을 참조하여 동일한 기능으로 및 디자인을 구현한다.
   대시보드: DashboardActivity.kt = DashboardSwiftUIView.swift

6. 프로젝트 구조 정리 (Mapping Guide)
   6-1. 프로젝트 구조 정리
   안드로이드 (참조용),SwiftUI (신규 생성),기능 설명
   ProductDescriptionFragment,ProductDescriptionView.swift,상품 상세 설명 (이미지/텍스트)
   ProductReviewFragment,ProductReviewView.swift,사용자 리뷰 목록
   ProductQAFragment,ProductQAView.swift,상품 Q&A 목록
   OrderActivity,OrderCheckoutView.swift,주문서 작성 및 배송지 관리
   PaymentWebViewActivity,PaymentWebView.swift,토스페이먼트 결제창 (WKWebView)
   OrderMgtActivity,OrderManagementView.swift,관리자용 주문 목록 (권한 제한)
   DashboardActivity,DashboardView.swift,통계 및 요약 화면
