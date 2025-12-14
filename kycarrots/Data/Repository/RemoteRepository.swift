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
    func registerUser(_ user: OpUserVO) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.registerUser(user: user),
            as: SimpleResultResponse.self
        )
    }

    func checkEmailDuplicate(email: String) async throws -> SimpleResult {
        try await api.request(
            AdApiEndpoint.checkEmailDuplicate(email: email),
            as: SimpleResult.self
        )
    }

    func getUserInfoByToken(token: String) async throws -> OpUserVO {
        try await api.request(
            AdApiEndpoint.getUserInfoByToken(token: token),
            as: OpUserVO.self
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
    func createOrGetChatRoom(productId: String, buyerId: String, sellerId: String) async throws -> ChatRoomResponse {
        try await api.request(
            AdApiEndpoint.createOrGetChatRoom(productId: productId, buyerId: buyerId, sellerId: sellerId),
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

    func getChatBuyers(productId: Int64, sellerId: String) async throws -> [ChatBuyerDto] {
        try await api.request(
            AdApiEndpoint.getChatBuyers(productId: productId, sellerId: sellerId),
            as: [ChatBuyerDto].self
        )
    }

    // MARK: - 도매상
    func getWholesalers(memberCode: String) async throws -> [OpUserVO] {
        try await api.request(
            AdApiEndpoint.getWholesalers(memberCode: memberCode),
            as: [OpUserVO].self
        )
    }

    func getDefaultWholesaler(userId: String) async throws -> OpUserVO {
        try await api.request(
            AdApiEndpoint.getDefaultWholesaler(userId: userId),
            as: OpUserVO.self
        )
    }

    func setDefaultWholesaler(userId: String, wholesalerNo: String) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.setDefaultWholesaler(userId: userId, wholesalerNo: wholesalerNo),
            as: SimpleResultResponse.self
        )
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
    func authSocial(_ req: SocialAuthRequest) async throws -> SocialAuthResponse {
        try await api.request(
            AdApiEndpoint.authSocial(req: req),
            as: SocialAuthResponse.self
        )
    }

    func linkSocial(_ req: LinkSocialRequest) async throws -> SimpleResultResponse {
        try await api.request(
            AdApiEndpoint.linkSocial(req: req),
            as: SimpleResultResponse.self
        )
    }
}
