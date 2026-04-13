//
//  AdApiEndpoint.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//  Android AdApi 를 기준으로 iOS용 Endpoint 정의
//

import Foundation

enum AdApiEndpoint: Endpoint {

    // 공통 코드
    case getCodeList(groupId: String)
    case getSCodeList(groupId: String, mcode: String)

    // 광고 리스트
    case getAdvertiseList(req: AdListRequest)
    case getBuyAdvertiseList(req: AdListRequest)

    // 광고 등록 / 수정 (Multipart → 나중에 별도 처리)
    case registerAdvertise(
        product: ProductVo,
        imageMetas: [ProductImageVo],
        images: [Data]
    )
    case updateAdvertise(
        product: ProductVo,
        imageMetas: [ProductImageVo],
        images: [Data]
    )

    // 상품 상세 / 이미지 삭제
    case getProductDetail(productId: Int64, userNo: Int64)
    case deleteImageById(imageId: String)

    // 리뷰 (Review)
    case getReviewList(productId: Int64)
    case insertReview(productId: String, rating: Int, contents: String, token: String, branchId: String, images: [Data]?)
    case updateReview(reviewId: String, rating: Int, contents: String, token: String, branchId: String, images: [Data]?)
    case deleteReview(reviewId: String, token: String)

    // 문의 (QnA)
    case getQnaList(productId: Int64)
    case insertQna(productId: String, title: String, contents: String, secretYn: String, token: String, branchId: String)
    case updateQna(qnaId: String, title: String, contents: String, secretYn: String, token: String, branchId: String)
    case deleteQna(qnaId: String, token: String)
    case answerQna(qnaId: String, answerContents: String, token: String)

    // 로그인 / 비번/이메일 찾기
    case login(
        email: String,
        password: String,
        loginCd: String,
        regId: String,
        appVersion: String,
        providerUserId: String
    )
    case findPassword(mail: String)
    case findEmail(name: String, phone: String)

    // 채팅
    case createOrGetChatRoom(productId: String, buyerId: String, branchId: String)
    case getUserChatRooms(productId: String, userId: String)
    case getChatMessages(roomId: String)

    // 회원 관련
    case checkEmailDuplicate(email: String)
    case registerUser(user: OpUserVO)
    case getUserInfoByToken(token: String)
    case updateUser(token: String, user: OpUserVO)
    case changePassword(token: String, request: PasswordChangeRequest)

    // 대시보드 / 최근 본 상품
    case getProductDashboard(token: String)
    case getRecentProducts(token: String)

    // 푸시 토큰 저장
    case registerPushToken(request: PushTokenVo)

    // 상품 상태 변경
    case updateProductStatus(token: String, product: ProductItem)

    // 관심상품 / 구매내역
    case toggleInterest(req: InterestRequest)
    case getInterestItems(token: String, pageNo: Int)
    case getPurchaseItems(token: String, pageNo: Int)

    // 채팅 구매자 / 구매 생성
    case getChatBuyers(productId: Int64, branchId: String)
    case createPurchase(body: PurchaseHistoryRequest)

    // 도매상(중간센터)

    // 이메일 인증 / 온보딩 / 소셜
    case sendEmailCode(req: EmailSendReq)
    case verifyEmailCode(req: EmailVerifyReq)
    case postOnboarding(req: OnboardingRequest)
    case authSocial(req: SocialAuthRequest)
    case linkSocial(req: LinkSocialRequest)
    case unlinkSocial(req: UnlinkSocialRequest)
    // 주문 (Order)
    case createOrder(req: OrderCreateRequest)
    case confirmPayment(req: PaymentConfirmRequest)
    case getOrderHistory(buyerNo: Int64, page: Int, size: Int)
    case getOrderDetail(orderId: String)
    case cancelPayment(req: OrderCancelRequest)
    case requestReturn(req: OrderReturnRequest)

    case getBranchList

    // 주소록 (Address)
    case getAddressList(token: String)
    case addAddress(token: String, address: TbAddressBookVo)
    case updateAddress(id: Int64, token: String, address: TbAddressBookVo)
    case deleteAddress(id: Int64, token: String)

    // 관리자 / 대시보드
    case getDashboardData(token: String)
    case getOrderMgtList(token: String, status: String?, stDate: String?, edDate: String?, keyword: String?)
    case getOrderMgtDetail(orderId: String, token: String)
    case updateOrderStatus(token: String, orderId: String, status: String)
    case confirmDeposit(token: String, orderId: String, carrier: String, tracking: String)
    case requestBranchDeposit(token: String, orderId: String)
    case updateShipping(token: String, orderId: String, carrier: String, tracking: String)

    // MARK: - Endpoint conformance

    var path: String {
        switch self {
        case .getCodeList:
            return "api/common/codelist"
        case .getSCodeList:
            return "api/common/sCodeList"

        case .getAdvertiseList:
            return "api/product"
        case .getBuyAdvertiseList:
            return "api/product/buyListAdvertise"

        case .registerAdvertise:
            return "api/product/register"
        case .updateAdvertise:
            return "api/product/update"

        case let .getProductDetail(productId, _):
            return "api/product/detail/\(productId)"
        case .deleteImageById:
            return "api/product/image/delete"

        case .getReviewList:
            return "api/product/review/list"
        case .insertReview:
            return "api/product/review/insert"
        case .deleteReview:
            return "api/product/review/delete"
        case .updateReview:
            return "api/product/review/update"

        case .getQnaList:
            return "api/product/qna/list"
        case .insertQna:
            return "api/product/qna/insert"
        case .updateQna:
            return "api/product/qna/update"
        case .deleteQna:
            return "api/product/qna/delete"
        case .answerQna:
            return "api/product/qna/answer"

        case .login:
            return "api/members/login"
        case .findPassword:
            return "api/members/find-password"
        case .findEmail:
            return "api/members/find-email"

        case .createOrGetChatRoom:
            return "api/chat/room"
        case let .getUserChatRooms(productId, userId):
            return "api/chat/rooms/\(productId)/\(userId)"
        case let .getChatMessages(roomId):
            return "api/chatmessage/list/\(roomId)"

        case .checkEmailDuplicate:
            return "api/members/email-check"
        case .registerUser:
            return "api/members/register"
        case .getUserInfoByToken:
            return "api/members/userinfo"
        case .updateUser:
            return "api/members/update"
        case .changePassword:
            return "api/members/change-password"

        case .getProductDashboard:
            return "api/product/dashboard"
        case .getRecentProducts:
            return "api/product/recent"

        case .registerPushToken:
            return "api/members/push/savetoken"

        case .updateProductStatus:
            return "api/product/status/update"

        case .toggleInterest:
            return "api/interests/toggle"
        case .getInterestItems:
            return "api/product/interests/list"
        case .getPurchaseItems:
            return "api/product/purchases/list"

        case .getChatBuyers:
            return "api/product/chat/buyers"
        case .createPurchase:
            return "api/purchases"


        case .sendEmailCode:
            return "api/email/send-code"
        case .verifyEmailCode:
            return "api/email/verify-code"
        case .postOnboarding:
            return "api/user/onboarding"
        case .authSocial:
            return "api/members/social"
        case .linkSocial:
            return "api/members/link"
        case .unlinkSocial:
            return "api/members/unlink"

        // Order
        case .createOrder:
            return "api/payment/order/create"
        case .confirmPayment:
            return "api/payment/confirm"
        case let .getOrderHistory(buyerNo, _, _):
            return "api/orders/buyer/\(buyerNo)"
        case .cancelPayment:
            return "api/payment/cancel"
        case .requestReturn:
            return "api/payment/return"
        case let .getOrderDetail(orderId):
            return "api/orders/\(orderId)"

        // Address
        case .getAddressList, .addAddress:
            return "api/members/address"
        case let .updateAddress(id, _, _):
            return "api/members/address/update/\(id)"
        case let .deleteAddress(id, _):
            return "api/members/address/delete/\(id)"

        // Dashboard / Order Mgt
        case .getDashboardData:
            return "api/dashboard"
        case .getOrderMgtList:
            return "api/order/list"
        case let .getOrderMgtDetail(orderId, _):
            return "api/order/\(orderId)"
        case .updateOrderStatus:
            return "api/order/status"
        case .confirmDeposit:
            return "api/order/confirmDeposit"
        case .requestBranchDeposit:
            return "api/order/requestBranchDeposit"
        case .updateShipping:
            return "api/order/updateShipping"
        case .getBranchList:
            return "api/branch/list"
        }
    }

    var method: HttpMethod {
        switch self {
        case .getCodeList,
             .getSCodeList,
             .getProductDetail,
             .findPassword,
             .findEmail,
             .getUserChatRooms,
             .getChatMessages,
             .getProductDashboard,
             .getRecentProducts,
             .getInterestItems,
             .getPurchaseItems,
             .getChatBuyers,
             .getReviewList,
             .getQnaList,
             .getOrderDetail,
             .getOrderHistory,
             .getAddressList,
             .getDashboardData,
             .getOrderMgtList,
             .getOrderMgtDetail,
             .getBranchList:
            return .get

        case .updateOrderStatus, .confirmDeposit, .requestBranchDeposit, .updateShipping:
            return .post

        default:
            return .post
        }
    }

    /// Retrofit의 @Query / @Field 에 해당하는 것들
    var query: [String : String]? {
        switch self {
        // 공통 코드
        case let .getCodeList(groupId):
            return ["groupId": groupId]

        case let .getSCodeList(groupId, mcode):
            return ["groupId": groupId, "mcode": mcode]

        // 상품 상세
        case let .getProductDetail(_, userNo):
            return ["userNo": String(userNo)]

        case let .deleteImageById(imageId):
            return ["imageId": imageId]

        case let .getReviewList(productId):
            return ["productId": String(productId)]
        case let .getQnaList(productId):
            return ["productId": String(productId)]

        case let .deleteReview(reviewId, token):
            return ["reviewId": reviewId, "token": token]
        case let .deleteQna(qnaId, token):
            return ["qnaId": qnaId, "token": token]
        case let .answerQna(qnaId, answerContents, token):
            return ["qnaId": qnaId, "answerContents": answerContents, "token": token]

        case let .insertReview(productId, rating, contents, token, branchId, _):
            return [
                "productId": productId, "rating": String(rating), "contents": contents,
                "token": token, "branchId": branchId
            ]
        case let .insertQna(productId, title, contents, secretYn, token, branchId):
            return [
                "productId": productId, "title": title, "contents": contents,
                "secretYn": secretYn, "token": token, "branchId": branchId
            ]
        case let .updateQna(qnaId, title, contents, secretYn, token, branchId):
            return [
                "qnaId": qnaId, "title": title, "contents": contents,
                "secretYn": secretYn, "token": token, "branchId": branchId
            ]
        case let .updateReview(reviewId, rating, contents, token, branchId, _):
            return [
                "reviewId": reviewId, "rating": String(rating), "contents": contents,
                "token": token, "branchId": branchId
            ]

        // 비밀번호/이메일 찾기
        case let .findPassword(mail):
            return ["mail": mail]

        case let .findEmail(name, phone):
            return ["nm": name, "hp": phone]

        // 채팅 관련
        case let .createOrGetChatRoom(productId, buyerId, branchId):
            return [
                "productId": productId,
                "buyerId": buyerId,
                "branchId": branchId
            ]

        // 로그인 (Android @FormUrlEncoded @Field 그대로 매핑)
        case let .login(email, password, loginCd, regId, appVersion, providerUserId):
            return [
                "id": email,
                "pass": password,
                "login_cd": loginCd,
                "reg_id": regId,
                "appver": appVersion,
                "providerUserId": providerUserId
            ]

        // 토큰/페이지 기반 리스트
        case let .getInterestItems(token, pageNo),
             let .getPurchaseItems(token, pageNo):
            return [
                "token": token,
                "pageno": String(pageNo)
            ]

        case let .getProductDashboard(token),
             let .getRecentProducts(token):
            return ["token": token]

        case let .updateProductStatus(token, _):
            return ["token": token]

        case let .getChatBuyers(productId, branchId):
            return [
                "productId": String(productId),
                "branchId": branchId
            ]

        // 도매상
        // @FormUrlEncoded email-check / userinfo → query 로 매핑
        case let .checkEmailDuplicate(email):
            return ["email": email]

        case let .getUserInfoByToken(token):
            return ["token": token]

        case let .updateUser(token, _):
            return ["token": token]

        case let .changePassword(token, _):
            return ["token": token]

        case let .getOrderHistory(_, page, size):
            return ["page": String(page), "size": String(size)]

        case let .getAddressList(token),
             let .addAddress(token, _):
            return ["token": token]

        case let .updateAddress(_, token, _),
             let .deleteAddress(_, token):
            return ["token": token]

        case let .getDashboardData(token):
            return ["token": token]

        case let .getOrderMgtList(token, status, stDate, edDate, keyword):
            var q = ["token": token]
            if let s = status { q["orderStatus"] = s }
            if let sd = stDate { q["orderStDt"] = sd }
            if let ed = edDate { q["orderEdDt"] = ed }
            if let k = keyword { q["searchKeyword"] = k }
            return q

        case let .getOrderMgtDetail(_, token):
            return ["token": token]

        case let .updateOrderStatus(token, orderId, status):
            return ["token": token, "orderId": orderId, "status": status]
        case let .confirmDeposit(token, orderId, carrier, tracking):
            return ["token": token, "orderId": orderId, "carrier": carrier, "trackingNo": tracking]
        case let .requestBranchDeposit(token, orderId):
            return ["token": token, "orderId": orderId]
        case let .updateShipping(token, orderId, carrier, tracking):
            return ["token": token, "orderId": orderId, "carrier": carrier, "trackingNo": tracking]

        default:
            return nil
        }
    }

    /// Retrofit의 @Body 에 해당하는 JSON Body
    var body: Encodable? {
        switch self {
        case let .getAdvertiseList(req),
             let .getBuyAdvertiseList(req):
            return req

        // Multipart 는 ApiClient 에서 별도 처리
        case .registerAdvertise,
             .updateAdvertise:
            return nil

        // 로그인은 @FormUrlEncoded → query 로만 보내므로 body 없음
        case .login:
            return nil

        // @FormUrlEncoded 로 보내는 애들 → body 없음
        case .checkEmailDuplicate,
             .getUserInfoByToken:
            return nil

        // JSON Body 사용하는 것들
        case let .registerUser(user):
            return user

        case let .updateUser(_, user):
            return user
            
        case let .changePassword(_, request):
            return request

        case let .registerPushToken(request):
            return request

        case let .updateProductStatus(_, product):
            return product

        case let .toggleInterest(req):
            return req

        case let .createPurchase(body):
            return body

        case let .sendEmailCode(req):
            return req

        case let .verifyEmailCode(req):
            return req

        case let .postOnboarding(req):
            return req

        case let .authSocial(req):
            return req

        case let .linkSocial(req):
            return req
        case let .unlinkSocial(req):
            return req

        // Order / Address JSON Body
        case let .createOrder(req):
            return req
        case let .confirmPayment(req):
            return req
        case let .cancelPayment(req):
            return req
        case let .requestReturn(req):
            return req
        case let .addAddress(_, address),
             let .updateAddress(_, _, address):
            return address

        default:
            return nil
        }
    }
}
