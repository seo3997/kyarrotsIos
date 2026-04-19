//
//  RemoteRepository.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

final class RemoteRepository {
    private let api: ApiClient

    init(api: ApiClient = .shared) {
        self.api = api
    }

    // MARK: - 코드 리스트
    func getCodeList(groupId: String) async throws -> [TxtListDataInfo] {
        try await api.request(
            AdApiEndpoint.getCodeList(groupId: groupId),
            as: [TxtListDataInfo].self
        )
    }

    func getSCodeList(groupId: String, mcode: String) async throws -> [TxtListDataInfo] {
        try await api.request(
            AdApiEndpoint.getSCodeList(groupId: groupId, mcode: mcode),
            as: [TxtListDataInfo].self
        )
    }

    // MARK: - 광고 리스트
    func getAdvertiseList(req: AdListRequest) async throws -> AdResponse {
        try await api.request(
            AdApiEndpoint.getAdvertiseList(req: req),
            as: AdResponse.self
        )
    }

    func getBuyAdvertiseList(req: AdListRequest) async throws -> AdResponse {
        try await api.request(
            AdApiEndpoint.getBuyAdvertiseList(req: req),
            as: AdResponse.self
        )
    }

    // MARK: - 상품 상세
    func getProductDetail(productId: Int64, userNo: Int64) async throws -> ProductDetailResponse {
        try await api.request(
            AdApiEndpoint.getProductDetail(productId: productId, userNo: userNo),
            as: ProductDetailResponse.self
        )
    }

    // MARK: - 이미지 삭제
    func deleteImageById(imageId: String) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.deleteImageById(imageId: imageId),
            as: SimpleResultResponse.self
        )
    }

    // MARK: - 관심상품
    func toggleInterest(req: InterestRequest) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.toggleInterest(req: req),
            as: SimpleResultResponse.self
        )
    }

    func getInterestItems(token: String, pageNo: Int) async throws -> AdResponse {
        try await api.request(
            AdApiEndpoint.getInterestItems(token: token, pageNo: pageNo),
            as: AdResponse.self
        )
    }

    // MARK: - 푸시 토큰 저장
    func registerPushToken(_ req: PushTokenVo) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.registerPushToken(request: req),
            as: SimpleResultResponse.self
        )
    }
    
    func registerAdvertise(
          product: ProductVo,
          imageMetas: [ProductImageVo],
          images: [Data]
      ) async throws -> SimpleResultResponse {
          // ✅ ApiClient에 multipart 업로드 함수가 있어야 함 (아래 3) 참고)
          try await api.uploadMultipart(
              AdApiEndpoint.registerAdvertise(product: product, imageMetas: imageMetas, images: images),
              as: SimpleResultResponse.self
          )
      }

      /// 광고 수정
      func updateAdvertise(
          product: ProductVo,
          imageMetas: [ProductImageVo],
          images: [Data]
      ) async throws -> SimpleResultResponse {
          try await api.uploadMultipart(
              AdApiEndpoint.updateAdvertise(product: product, imageMetas: imageMetas, images: images),
              as: SimpleResultResponse.self
          )
      }
    
    // MARK: - 로그인 / 이메일/비번
    func login(
        email: String,
        password: String,
        loginCd: String,
        regId: String,
        appVersion: String,
        providerUserId: String
    ) async throws -> LoginResponse {
        try await api.request(
            AdApiEndpoint.login(email: email,
                                password: password,
                                loginCd: loginCd,
                                regId: regId,
                                appVersion: appVersion,
                                providerUserId: providerUserId),
            as: LoginResponse.self
        )
    }

    func findPassword(email: String) async throws -> StringResponse {
        try await api.request(
            AdApiEndpoint.findPassword(mail: email),
            as: StringResponse.self
        )
    }

    func findEmail(name: String, phone: String) async throws -> StringResponse {
        try await api.request(
            AdApiEndpoint.findEmail(name: name, phone: phone),
            as: StringResponse.self
        )
    }

    // MARK: - 회원가입
    func registerUser(_ user: OpUserVO) async throws -> LoginResponse {
        try await api.request(
            AdApiEndpoint.registerUser(user: user),
            as: LoginResponse.self
        )
    }

    func checkEmailDuplicate(email: String) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.checkEmailDuplicate(email: email),
            as: SimpleResultResponse.self
        )
    }

    func getUserInfoByToken(token: String) async throws -> OpUserVO {
        try await api.request(
            AdApiEndpoint.getUserInfoByToken(token: token),
            as: OpUserVO.self
        )
    }

    func updateUser(token: String, user: OpUserVO) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.updateUser(token: token, user: user),
            as: SimpleResultResponse.self
        )
    }

    func changePassword(token: String, request: PasswordChangeRequest) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.changePassword(token: token, request: request),
            as: SimpleResultResponse.self
        )
    }

    // MARK: - 대시보드 / 최근 본 상품
    func getProductDashboard(token: String) async throws -> [String: Int] {
        try await api.request(
            AdApiEndpoint.getProductDashboard(token: token),
            as: [String: Int].self
        )
    }
    
    func getRecentProducts(token: String) async throws -> [ProductVo] {
        try await api.request(
            AdApiEndpoint.getRecentProducts(token: token),
            as: [ProductVo].self
        )
    }
    
    // MARK: - 상품 상태 변경
    func updateProductStatus(token: String, product: ProductItem) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.updateProductStatus(token: token, product: product),
            as: SimpleResultResponse.self
        )
    }

    // MARK: - 구매내역
    func getPurchaseItems(token: String, pageNo: Int) async throws -> AdResponse {
        try await api.request(
            AdApiEndpoint.getPurchaseItems(token: token, pageNo: pageNo),
            as: AdResponse.self
        )
    }

    func createPurchase(_ req: PurchaseHistoryRequest) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.createPurchase(body: req),
            as: SimpleResultResponse.self
        )
    }

    // MARK: - 채팅
    func createOrGetChatRoom(productId: String, buyerId: String, branchId: String) async throws -> ChatRoomResponse {
        try await api.request(
            AdApiEndpoint.createOrGetChatRoom(productId: productId, buyerId: buyerId, branchId: branchId),
            as: ChatRoomResponse.self
        )
    }

    func getUserChatRooms(productId: String, userId: String) async throws -> [ChatRoomResponse] {
        try await api.request(
            AdApiEndpoint.getUserChatRooms(productId: productId, userId: userId),
            as: [ChatRoomResponse].self
        )
    }

    func getChatMessages(roomId: String) async throws -> [ChatMessageResponse] {
        try await api.request(
            AdApiEndpoint.getChatMessages(roomId: roomId),
            as: [ChatMessageResponse].self
        )
    }

    func getChatBuyers(productId: Int64, branchId: String) async throws -> [ChatBuyerDto] {
        try await api.request(
            AdApiEndpoint.getChatBuyers(productId: productId, branchId: branchId),
            as: [ChatBuyerDto].self
        )
    }


    func getBranchList() async throws -> [BranchInfoVo] {
        try await api.request(AdApiEndpoint.getBranchList, as: [BranchInfoVo].self)
    }


    // MARK: - 이메일 인증
    func sendEmailCode(_ req: EmailSendReq) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.sendEmailCode(req: req),
            as: SimpleResultResponse.self
        )
    }

    func verifyEmailCode(_ req: EmailVerifyReq) async throws -> EmailVerifyResp {
        try await api.request(
            AdApiEndpoint.verifyEmailCode(req: req),
            as: EmailVerifyResp.self
        )
    }

    // MARK: - 온보딩
    func postOnboarding(_ req: OnboardingRequest) async throws -> OnboardingResponse {
        try await api.request(
            AdApiEndpoint.postOnboarding(req: req),
            as: OnboardingResponse.self
        )
    }

    // MARK: - 소셜 로그인
    func authSocial(_ req: SocialAuthRequest) async throws -> LoginResponse {
        try await api.request(
            AdApiEndpoint.authSocial(req: req),
            as: LoginResponse.self
        )
    }

    func linkSocial(_ req: LinkSocialRequest) async throws -> LoginResponse {
        try await api.request(
            AdApiEndpoint.linkSocial(req: req),
            as: LoginResponse.self
        )
    }
    func unlinkSocial(_ req: UnlinkSocialRequest) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.unlinkSocial(req: req),
            as: SimpleResultResponse.self
        )
    }

    // MARK: - 리뷰 (Review)
    func fetchReviewList(productId: Int64) async throws -> ReviewListResponse {
        try await api.request(
            AdApiEndpoint.getReviewList(productId: productId),
            as: ReviewListResponse.self
        )
    }

    func insertReview(productId: String, rating: Int, contents: String, token: String, branchId: String, images: [Data]?) async throws -> SimpleResultResponse {
        if let images = images, !images.isEmpty {
            return try await api.uploadMultipart(
                AdApiEndpoint.insertReview(productId: productId, rating: rating, contents: contents, token: token, branchId: branchId, images: images),
                as: SimpleResultResponse.self
            )
        } else {
            return try await api.request(
                AdApiEndpoint.insertReview(productId: productId, rating: rating, contents: contents, token: token, branchId: branchId, images: nil),
                as: SimpleResultResponse.self
            )
        }
    }

    func updateReview(reviewId: String, rating: Int, contents: String, token: String, branchId: String, images: [Data]?) async throws -> SimpleResultResponse {
        if let images = images, !images.isEmpty {
            return try await api.uploadMultipart(
                AdApiEndpoint.updateReview(reviewId: reviewId, rating: rating, contents: contents, token: token, branchId: branchId, images: images),
                as: SimpleResultResponse.self
            )
        } else {
            return try await api.request(
                AdApiEndpoint.updateReview(reviewId: reviewId, rating: rating, contents: contents, token: token, branchId: branchId, images: nil),
                as: SimpleResultResponse.self
            )
        }
    }

    func deleteReview(reviewId: String, token: String) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.deleteReview(reviewId: reviewId, token: token),
            as: SimpleResultResponse.self
        )
    }

    // MARK: - 문의 (QnA)
    func fetchQnaList(productId: Int64) async throws -> QnaListResponse {
        try await api.request(
            AdApiEndpoint.getQnaList(productId: productId),
            as: QnaListResponse.self
        )
    }

    func insertQna(productId: String, title: String, contents: String, secretYn: String, token: String, branchId: String) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.insertQna(productId: productId, title: title, contents: contents, secretYn: secretYn, token: token, branchId: branchId),
            as: SimpleResultResponse.self
        )
    }

    func updateQna(qnaId: String, title: String, contents: String, secretYn: String, token: String, branchId: String) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.updateQna(qnaId: qnaId, title: title, contents: contents, secretYn: secretYn, token: token, branchId: branchId),
            as: SimpleResultResponse.self
        )
    }

    func deleteQna(qnaId: String, token: String) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.deleteQna(qnaId: qnaId, token: token),
            as: SimpleResultResponse.self
        )
    }

    func answerQna(qnaId: String, answerContents: String, token: String) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.answerQna(qnaId: qnaId, answerContents: answerContents, token: token),
            as: SimpleResultResponse.self
        )
    }

    // MARK: - 주문 (Order)
    func createOrder(req: OrderCreateRequest) async throws -> OrderCreateResponse {
        try await api.request(AdApiEndpoint.createOrder(req: req), as: OrderCreateResponse.self)
    }

    func confirmPayment(req: PaymentConfirmRequest) async throws -> PaymentConfirmResponse {
        try await api.request(AdApiEndpoint.confirmPayment(req: req), as: PaymentConfirmResponse.self)
    }

    func getOrderHistory(buyerNo: Int64, page: Int, size: Int = 10) async throws -> AdResponse {
        try await api.request(AdApiEndpoint.getOrderHistory(buyerNo: buyerNo, page: page, size: size), as: AdResponse.self)
    }

    func getOrderDetail(orderId: String) async throws -> OrderDetailResponse {
        try await api.request(AdApiEndpoint.getOrderDetail(orderId: orderId), as: OrderDetailResponse.self)
    }

    func cancelPayment(req: OrderCancelRequest) async throws -> PaymentCancelResponse {
        try await api.request(AdApiEndpoint.cancelPayment(req: req), as: PaymentCancelResponse.self)
    }

    func requestReturn(req: OrderReturnRequest) async throws -> PaymentCancelResponse {
        try await api.request(AdApiEndpoint.requestReturn(req: req), as: PaymentCancelResponse.self)
    }

    // MARK: - 주소록 (Address)
    func getAddressList(token: String) async throws -> AddressListResponse {
        try await api.request(AdApiEndpoint.getAddressList(token: token), as: AddressListResponse.self)
    }

    func addAddress(token: String, address: TbAddressBookVo) async throws -> SimpleResultResponse {
        try await api.request(AdApiEndpoint.addAddress(token: token, address: address), as: SimpleResultResponse.self)
    }

    func updateAddress(id: Int64, token: String, address: TbAddressBookVo) async throws -> SimpleResultResponse {
        try await api.request(AdApiEndpoint.updateAddress(id: id, token: token, address: address), as: SimpleResultResponse.self)
    }

    func deleteAddress(id: Int64, token: String) async throws -> SimpleResultResponse {
        try await api.request(AdApiEndpoint.deleteAddress(id: id, token: token), as: SimpleResultResponse.self)
    }

    // MARK: - 관리자 / 대시보드
    func getDashboardMgtData(token: String) async throws -> [String: Any] {
        return try await api.request(AdApiEndpoint.getDashboardData(token: token), as: [String: AnyCodable].self).mapValues { $0.value }
    }

    func getOrderMgtList(token: String, status: String?, stDate: String?, edDate: String?, keyword: String?) async throws -> [String: Any] {
        try await api.request(AdApiEndpoint.getOrderMgtList(token: token, status: status, stDate: stDate, edDate: edDate, keyword: keyword), as: [String: AnyCodable].self).mapValues { $0.value }
    }

    func getOrderMgtDetail(orderId: String, token: String) async throws -> [String: Any] {
        try await api.request(AdApiEndpoint.getOrderMgtDetail(orderId: orderId, token: token), as: [String: AnyCodable].self).mapValues { $0.value }
    }

    func updateOrderStatus(token: String, orderId: String, status: String) async throws -> SimpleResultResponse {
        try await api.request(AdApiEndpoint.updateOrderStatus(token: token, orderId: orderId, status: status), as: SimpleResultResponse.self)
    }

    func confirmDeposit(token: String, orderId: String, carrier: String, tracking: String) async throws -> SimpleResultResponse {
        try await api.request(AdApiEndpoint.confirmDeposit(token: token, orderId: orderId, carrier: carrier, tracking: tracking), as: SimpleResultResponse.self)
    }

    func requestBranchDeposit(token: String, orderId: String) async throws -> SimpleResultResponse {
        try await api.request(AdApiEndpoint.requestBranchDeposit(token: token, orderId: orderId), as: SimpleResultResponse.self)
    }

    func updateShipping(token: String, orderId: String, carrier: String, tracking: String) async throws -> SimpleResultResponse {
        try await api.request(AdApiEndpoint.updateShipping(token: token, orderId: orderId, carrier: carrier, tracking: tracking), as: SimpleResultResponse.self)
    }
}

// Simple AnyCodable helper to handle Map<String, Any> from Android
struct AnyCodable: Decodable {
    let value: Any
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(String.self) { value = v }
        else if let v = try? container.decode(Int.self) { value = v }
        else if let v = try? container.decode(Double.self) { value = v }
        else if let v = try? container.decode(Bool.self) { value = v }
        else if let v = try? container.decode([String: AnyCodable].self) { value = v.mapValues { $0.value } }
        else if let v = try? container.decode([AnyCodable].self) { value = v.map { $0.value } }
        else { value = NSNull() }
    }
}
