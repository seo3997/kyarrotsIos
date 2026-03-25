1. push 수신시 이동
   1-1 push 수신시 이동을 안드로이드 동일하게 구현한다.

   안드로이드 소스: /Users/soo/kycarrotsApp/app/src/main/java/com/whomade/kycarrots/message/MyFirebaseMessagingService.kt 의 onMessageReceived 메소드 참조

   1-2 push 수신시 저장되는 테이블

   NotificationModel 참조
   targetId 추가
   productId,roomId,sellerId 삭제됨
   MyFirebaseMessagingService.kt savePushLocally 메소드 참조
   안드로이드 소스: com.whomade.kycarrots.data.local.entity.NotificationModel.kt

   1-3 push 수신시 이동하는 화면
   안드로이드 소스: com.whomade.kycarrots.ui.intro.IntroActivity.kt
   createIntentsForPushNavigation 메소드 참조
   pushType 별로 분기
   pushType 화면
   chat 채팅장이동 ChatActivity.kt
   product 상품상세 ProductDetailActivity.kt
   order 주문상세 로그인권한이 ROLE_SELL,ROLE_PROJ,ROLE_ADMIN 인경우  
    OrderMgtDetailActivity.kt
   로그인권한 ROLE_PUB 인경우 OrderDetailActivity.kt
   iOs이동 화면
   chat 채팅장이동 ChatSwiftUIView.swift
   product 상품상세 ProductDetailSwiftUIView.swift
   order 주문상세 로그인권한이 ROLE_SELL,ROLE_PROJ,ROLE_ADMIN 인경우  
    OrderManagementDetailView.swift
   로그인권한 ROLE_PUB 인경우 OrderDetailView.swift
