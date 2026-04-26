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
        do { return try await repo.getAdvertiseList(req: req).adItems }
        catch { return [] }
    }

    func getBuyAdvertiseList(req: AdListRequest) async -> [AdItem] {
        do { return try await repo.getBuyAdvertiseList(req: req).adItems }
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
        (try? await repo.getInterestItems(token: token, pageNo: pageNo).adItems) ?? []
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
    func registerUser(_ user: OpUserVO) async -> LoginResponse? {
        do {
                return try await repo.registerUser(user)
            } catch {
                return nil
            }
    }

    func checkEmailDuplicate(email: String) async -> SimpleResultResponse? {
        try? await repo.checkEmailDuplicate(email: email)
    }

    func getUserInfoByToken(token: String) async -> OpUserVO? {
        try? await repo.getUserInfoByToken(token: token)
    }

    func updateUser(token: String, user: OpUserVO) async -> Bool {
        (try? await repo.updateUser(token: token, user: user).result) ?? false
    }

    func changePassword(token: String, request: PasswordChangeRequest) async -> (Bool, String) {
        do {
            let res = try await repo.changePassword(token: token, request: request)
            return (res.result, res.message ?? "")
        } catch {
            return (false, error.localizedDescription)
        }
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
        do {
            let response = try await repo.updateProductStatus(token: token, product: product)
            return response.result
        } catch {
            return false
        }
    }
    // 구매내역
    func getPurchaseItems(token: String, pageNo: Int) async -> [AdItem] {
        (try? await repo.getPurchaseItems(token: token, pageNo: pageNo).adItems) ?? []
    }

    func createPurchase(_ req: PurchaseHistoryRequest) async -> Bool {
        (try? await repo.createPurchase(req).result) ?? false
    }

    // 채팅
    func createOrGetChatRoom(productId: String, buyerId: String, branchId: String)
    async -> ChatRoomResponse? {
        try? await repo.createOrGetChatRoom(productId: productId, buyerId: buyerId, branchId: branchId)
    }

    func getUserChatRooms(productId: String, userId: String)
    async -> [ChatRoomResponse] {
        (try? await repo.getUserChatRooms(productId: productId, userId: userId)) ?? []
    }

    func getChatMessages(roomId: String) async -> [ChatMessageResponse] {
        (try? await repo.getChatMessages(roomId: roomId)) ?? []
    }

    func getChatBuyers(productId: Int64, branchId: String) async -> [ChatBuyerDto] {
        (try? await repo.getChatBuyers(productId: productId, branchId: branchId)) ?? []
    }

    // 판매지점리스트
    func getBranchList() async -> [BranchInfoVo] {
        (try? await repo.getBranchList()) ?? []
    }

    func getBranchInfo(branchId: Int64) async -> BranchInfoVo? {
        try? await repo.getBranchInfo(branchId: branchId)
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
    func authSocial(_ req: SocialAuthRequest) async -> LoginResponse? {
        try? await repo.authSocial(req)
    }

    func linkSocial(_ req: LinkSocialRequest) async -> LoginResponse? {
        try? await repo.linkSocial(req)
    }
    
    func unlinkSocial(_ req: UnlinkSocialRequest) async -> SimpleResultResponse? {
        try? await repo.unlinkSocial(req)
    }

    // MARK: - 리뷰 (Review)
    func getReviewList(productId: Int64) async -> [ReviewVo] {
        (try? await repo.fetchReviewList(productId: productId).reviews) ?? []
    }

    func insertReview(productId: String, rating: Int, contents: String, token: String, branchId: String, images: [Data]?) async -> Bool {
        (try? await repo.insertReview(productId: productId, rating: rating, contents: contents, token: token, branchId: branchId, images: images).result) ?? false
    }

    func updateReview(reviewId: String, rating: Int, contents: String, token: String, branchId: String, images: [Data]?) async -> Bool {
        (try? await repo.updateReview(reviewId: reviewId, rating: rating, contents: contents, token: token, branchId: branchId, images: images).result) ?? false
    }

    func deleteReview(reviewId: String, token: String) async -> Bool {
        (try? await repo.deleteReview(reviewId: reviewId, token: token).result) ?? false
    }

    // MARK: - 문의 (QnA)
    func getQnaList(productId: Int64) async -> [QnaVo] {
        (try? await repo.fetchQnaList(productId: productId).qnas) ?? []
    }

    func insertQna(productId: String, title: String, contents: String, secretYn: String, token: String, branchId: String) async -> Bool {
        (try? await repo.insertQna(productId: productId, title: title, contents: contents, secretYn: secretYn, token: token, branchId: branchId).result) ?? false
    }

    func updateQna(qnaId: String, title: String, contents: String, secretYn: String, token: String, branchId: String) async -> Bool {
        (try? await repo.updateQna(qnaId: qnaId, title: title, contents: contents, secretYn: secretYn, token: token, branchId: branchId).result) ?? false
    }

    func deleteQna(qnaId: String, token: String) async -> Bool {
        (try? await repo.deleteQna(qnaId: qnaId, token: token).result) ?? false
    }

    func answerQna(qnaId: String, answerContents: String, token: String) async -> Bool {
        (try? await repo.answerQna(qnaId: qnaId, answerContents: answerContents, token: token).result) ?? false
    }

    // MARK: - 주문 (Order)
    func createOrder(req: OrderCreateRequest) async -> OrderCreateResponse? {
        try? await repo.createOrder(req: req)
    }

    func confirmPayment(req: PaymentConfirmRequest) async -> Bool {
        (try? await repo.confirmPayment(req: req).success) ?? false
    }

    func getOrderHistory(buyerNo: Int64, page: Int) async -> [AdItem] {
        (try? await repo.getOrderHistory(buyerNo: buyerNo, page: page).adItems) ?? []
    }

    func getOrderDetail(orderId: String) async -> OrderDetailResponse? {
        try? await repo.getOrderDetail(orderId: orderId)
    }

    func cancelPayment(req: OrderCancelRequest) async -> PaymentCancelResponse? {
        try? await repo.cancelPayment(req: req)
    }

    func requestReturn(req: OrderReturnRequest) async -> PaymentCancelResponse? {
        try? await repo.requestReturn(req: req)
    }

    // MARK: - 주소록 (Address)
    func getAddressList(token: String) async -> [TbAddressBookVo] {
        (try? await repo.getAddressList(token: token).addresses) ?? []
    }

    func addAddress(token: String, address: TbAddressBookVo) async -> Bool {
        (try? await repo.addAddress(token: token, address: address).result) ?? false
    }

    func updateAddress(id: Int64, token: String, address: TbAddressBookVo) async -> Bool {
        (try? await repo.updateAddress(id: id, token: token, address: address).result) ?? false
    }

    func deleteAddress(id: Int64, token: String) async -> Bool {
        (try? await repo.deleteAddress(id: id, token: token).result) ?? false
    }

    // MARK: - 관리자 (Admin)
    func getDashboardMgtData(token: String) async -> [String: Any]? {
        try? await repo.getDashboardMgtData(token: token)
    }

    func getOrderMgtList(token: String, status: String?, stDate: String?, edDate: String?, keyword: String?) async -> [String: Any]? {
        try? await repo.getOrderMgtList(token: token, status: status, stDate: stDate, edDate: edDate, keyword: keyword)
    }

    func getOrderMgtDetail(orderId: String, token: String) async -> [String: Any]? {
        try? await repo.getOrderMgtDetail(orderId: orderId, token: token)
    }

    func updateOrderStatus(token: String, orderId: String, status: String) async -> SimpleResultResponse? {
        try? await repo.updateOrderStatus(token: token, orderId: orderId, status: status)
    }

    func confirmDeposit(token: String, orderId: String, carrier: String, tracking: String) async -> SimpleResultResponse? {
        try? await repo.confirmDeposit(token: token, orderId: orderId, carrier: carrier, tracking: tracking)
    }

    func requestBranchDeposit(token: String, orderId: String) async -> SimpleResultResponse? {
        try? await repo.requestBranchDeposit(token: token, orderId: orderId)
    }

    func updateShipping(token: String, orderId: String, carrier: String, tracking: String) async -> SimpleResultResponse? {
        try? await repo.updateShipping(token: token, orderId: orderId, carrier: carrier, tracking: tracking)
    }


    // Android처럼 TODO 유지
    func saveJwt(_ jwt: String) {
        // TODO: Keychain / UserDefaults 등에 저장
    }
}
