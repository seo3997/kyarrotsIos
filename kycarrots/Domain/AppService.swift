//
//  AppService.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

final class AppService {
    private let repo: RemoteRepository

    init(repo: RemoteRepository) {
        self.repo = repo
    }

    // 광고 리스트
    func getAdvertiseList(req: AdListRequest) async -> [AdItem] {
        do { return try await repo.getAdvertiseList(req: req).items }
        catch { return [] }
    }

    func getBuyAdvertiseList(req: AdListRequest) async -> [AdItem] {
        do { return try await repo.getBuyAdvertiseList(req: req).items }
        catch { return [] }
    }

    func registerAdvertise(
        product: ProductVo,
        imageMetas: [ProductImageVo],
        images: [Data]
    ) async -> Bool {
        (try? await repo.registerAdvertise(product: product, imageMetas: imageMetas, images: images).result) ?? false
    }

    func updateAdvertise(
        product: ProductVo,
        imageMetas: [ProductImageVo],
        images: [Data]
    ) async -> Bool {
        (try? await repo.updateAdvertise(product: product, imageMetas: imageMetas, images: images).result) ?? false
    }
    // 코드 리스트 조회
    func getCodeList(groupId: String) async -> [TxtListDataInfo] {
        (try? await repo.getCodeList(groupId: groupId)) ?? []
    }

    // 코드(서브) 리스트 조회
    func getSCodeList(groupId: String, mcode: String) async -> [TxtListDataInfo] {
        (try? await repo.getSCodeList(groupId: groupId, mcode: mcode)) ?? []
    }

    // 상품 상세
    func getProductDetail(productId: Int64, userNo: Int64) async -> ProductDetailResponse? {
        try? await repo.getProductDetail(productId: productId, userNo: userNo)
    }

    // 관심상품
    func toggleInterest(_ req: InterestRequest) async -> Bool {
        (try? await repo.toggleInterest(req: req).result) ?? false
    }

    func getInterestItems(token: String, pageNo: Int) async -> [AdItem] {
        (try? await repo.getInterestItems(token: token, pageNo: pageNo).items) ?? []
    }

    // 푸시 토큰 저장
    func savePushToken(_ req: PushTokenVo) async -> Bool {
        do {
            let res = try await repo.registerPushToken(req)
            if !res.result {
                print("❌ savePushToken fail:", res.message)
            }
            return res.result
        } catch {
            print("❌ savePushToken error:", error)
            return false
        }
    }
    // 로그인
    func login(
        email: String,
        password: String,
        loginCd: String,
        regId: String,
        appVersion: String,
        providerUserId: String
    ) async -> LoginResponse? {
        let res = try? await repo.login(
            email: email,
            password: password,
            loginCd: loginCd,
            regId: regId,
            appVersion: appVersion,
            providerUserId: providerUserId
        )
        //print("🔥 temp = \(String(describing: res))")
        if let token = res?.token {
            NetworkConfig.accessToken = token
        }
        return res
    }

    func findPassword(email: String) async -> String? {
        try? await repo.findPassword(email: email).resultString
    }

    func findEmail(name: String, phone: String) async -> String? {
        try? await repo.findEmail(name: name, phone: phone).resultString
    }

    // 회원가입
    func registerUser(_ user: OpUserVO) async -> Bool {
        (try? await repo.registerUser(user).result) ?? false
    }

    func checkEmailDuplicate(email: String) async -> Bool {
        (try? await repo.checkEmailDuplicate(email: email).result) ?? false
    }

    func getUserInfoByToken(token: String) async -> OpUserVO? {
        try? await repo.getUserInfoByToken(token: token)
    }

    // 대시보드
    func getProductDashboard(token: String) async throws -> [String: Int] {
        try await repo.getProductDashboard(token: token)
    }
    
    func getRecentProducts(token: String) async -> [ProductVo] {
        (try? await repo.getRecentProducts(token: token)) ?? []
    }

    // 상품 상태 변경
    func updateProductStatus(token: String, product: ProductItem) async -> Bool {
        (try? await repo.updateProductStatus(token: token, product: product).result) ?? false
    }

    // 구매내역
    func getPurchaseItems(token: String, pageNo: Int) async -> [AdItem] {
        (try? await repo.getPurchaseItems(token: token, pageNo: pageNo).items) ?? []
    }

    func createPurchase(_ req: PurchaseHistoryRequest) async -> Bool {
        (try? await repo.createPurchase(req).result) ?? false
    }

    // 채팅
    func createOrGetChatRoom(productId: String, buyerId: String, sellerId: String)
    async -> ChatRoomResponse? {
        try? await repo.createOrGetChatRoom(productId: productId, buyerId: buyerId, sellerId: sellerId)
    }

    func getUserChatRooms(productId: String, userId: String)
    async -> [ChatRoomResponse] {
        (try? await repo.getUserChatRooms(productId: productId, userId: userId)) ?? []
    }

    func getChatMessages(roomId: String) async -> [ChatMessageResponse] {
        (try? await repo.getChatMessages(roomId: roomId)) ?? []
    }

    func getChatBuyers(productId: Int64, sellerId: String) async -> [ChatBuyerDto] {
        (try? await repo.getChatBuyers(productId: productId, sellerId: sellerId)) ?? []
    }

    // 도매상
    func getWholesalers(memberCode: String) async -> [OpUserVO] {
        (try? await repo.getWholesalers(memberCode: memberCode)) ?? []
    }

    func getDefaultWholesaler(userId: String) async throws -> Int64 {
        try await repo.getDefaultWholesaler(userId: userId)
    }
    
    func setDefaultWholesaler(userId: String, wholesalerNo: String) async -> Bool {
        (try? await repo.setDefaultWholesaler(userId: userId, wholesalerNo: wholesalerNo).result) ?? false
    }

    // 이메일 인증
    func sendEmailCode(_ req: EmailSendReq) async -> Bool {
        (try? await repo.sendEmailCode(req).result) ?? false
    }

    func verifyEmailCode(_ req: EmailVerifyReq) async -> Bool {
        (try? await repo.verifyEmailCode(req).verified) ?? false
    }

    // 온보딩
    func postOnboarding(_ req: OnboardingRequest) async -> OnboardingResponse? {
        try? await repo.postOnboarding(req)
    }

    // 소셜 로그인
    func authSocial(_ req: SocialAuthRequest) async -> SocialAuthResponse? {
        try? await repo.authSocial(req)
    }

    func linkSocial(_ req: LinkSocialRequest) async -> Bool {
        (try? await repo.linkSocial(req).result) ?? false
    }
}
