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
    case getAdItems(req: AdListRequest)
    case getBuyAdItems(req: AdListRequest)

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
    case createOrGetChatRoom(productId: String, buyerId: String, sellerId: String)
    case getUserChatRooms(productId: String, userId: String)
    case getChatMessages(roomId: String)

    // 회원 관련
    case checkEmailDuplicate(email: String)
    case registerUser(user: OpUserVO)
    case getUserInfoByToken(token: String)

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
    case getChatBuyers(productId: Int64, sellerId: String)
    case createPurchase(body: PurchaseHistoryRequest)

    // 도매상(중간센터)
    case getWholesalers(memberCode: String)
    case getDefaultWholesaler(userId: String)
    case setDefaultWholesaler(userId: String, wholesalerNo: String)

    // 이메일 인증 / 온보딩 / 소셜
    case sendEmailCode(req: EmailSendReq)
    case verifyEmailCode(req: EmailVerifyReq)
    case postOnboarding(req: OnboardingRequest)
    case authSocial(req: SocialAuthRequest)
    case linkSocial(req: LinkSocialRequest)

    // MARK: - Endpoint conformance

    var path: String {
        switch self {
        case .getCodeList:
            return "api/common/codelist"
        case .getSCodeList:
            return "api/common/sCodeList"

        case .getAdItems:
            return "api/product"
        case .getBuyAdItems:
            return "api/product/buyListAdvertise"

        case .registerAdvertise:
            return "api/product/register"
        case .updateAdvertise:
            return "api/product/update"

        case let .getProductDetail(productId, _):
            return "api/product/detail/\(productId)"
        case .deleteImageById:
            return "api/product/image/delete"

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

        case .getWholesalers:
            return "api/members/wholesalers"
        case .getDefaultWholesaler,
             .setDefaultWholesaler:
            return "api/members/default-wholesaler"

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
             .getWholesalers,
             .getDefaultWholesaler:
            return .get

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

        // 비밀번호/이메일 찾기
        case let .findPassword(mail):
            return ["mail": mail]

        case let .findEmail(name, phone):
            return ["nm": name, "hp": phone]

        // 채팅 관련
        case let .createOrGetChatRoom(productId, buyerId, sellerId):
            return [
                "productId": productId,
                "buyerId": buyerId,
                "sellerId": sellerId
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

        case let .getChatBuyers(productId, sellerId):
            return [
                "productId": String(productId),
                "sellerId": sellerId
            ]

        // 도매상
        case let .getWholesalers(memberCode):
            return ["memberCode": memberCode]

        case let .getDefaultWholesaler(userId):
            return ["userId": userId]

        case let .setDefaultWholesaler(userId, wholesalerNo):
            return [
                "userId": userId,
                "wholesalerNo": wholesalerNo
            ]

        // @FormUrlEncoded email-check / userinfo → query로 매핑
        case let .checkEmailDuplicate(email):
            return ["email": email]

        case let .getUserInfoByToken(token):
            return ["token": token]

        default:
            return nil
        }
    }

    /// Retrofit의 @Body 에 해당하는 JSON Body
    var body: Encodable? {
        switch self {
        case let .getAdItems(req),
             let .getBuyAdItems(req):
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

        default:
            return nil
        }
    }
}
