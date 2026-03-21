//
//  LoginInfoUtil.swift
//  kycarrots
//

import Foundation

struct LoginInfoUtil {

    // Android: public const val PREF_NAME = "SaveLoginInfo"
    static let PREF_NAME = "SaveLoginInfo"

    // Android Key 대응
    static let KEY_ID          = "LogIn_ID"
    static let KEY_NO          = "LogIn_NO"
    static let KEY_NM          = "LogIn_NM"
    static let KEY_PWD         = "LogIn_PWD"
    static let KEY_MEMBER_CODE = "LogIn_MEMBERCODE"
    static let KEY_IS_LOGIN    = "IsLogin"
    static let KEY_LOGIN_CD    = "LogIn_CD"
    static let KEY_SOCIAL_ID   = "LogIn_SOCIAL_ID"
    static let KEY_BRANCH_ID    = "LogIn_BRANCH_ID"
    static let KEY_BRANCH_NAME  = "LogIn_BRANCH_NAME"
    static let KEY_TOSS_CLIENT_KEY = "LogIn_TOSS_CLIENT_KEY"
    static let KEY_BASE_SHIPPING_FEE = "LogIn_BASE_SHIPPING_FEE"
    static let KEY_FREE_SHIPPING_THRESHOLD = "LogIn_FREE_SHIPPING_THRESHOLD"

    private static let defaults = UserDefaults.standard

    // Android saveLoginInfo() 동일
    static func saveLoginInfo(
        email: String,
        loginNo: String,
        password: String,
        memberCode: String,
        loginNm: String,
        loginCd: String,
        loginSocialId: String,
        branchId: String? = nil,
        branchName: String? = nil,
        tossClientKey: String? = nil,
        baseShippingFee: Int = 0,
        freeShippingThreshold: Int = 0
    ) {
        defaults.set(email,        forKey: KEY_ID)
        defaults.set(loginNo,      forKey: KEY_NO)
        defaults.set(loginNm,      forKey: KEY_NM)
        defaults.set(password,     forKey: KEY_PWD)
        defaults.set(memberCode,   forKey: KEY_MEMBER_CODE)
        defaults.set(true,         forKey: KEY_IS_LOGIN)
        defaults.set(loginCd,      forKey: KEY_LOGIN_CD)
        defaults.set(loginSocialId,forKey: KEY_SOCIAL_ID)
        defaults.set(branchId ?? "",     forKey: KEY_BRANCH_ID)
        defaults.set(branchName ?? "",   forKey: KEY_BRANCH_NAME)
        defaults.set(tossClientKey ?? "",forKey: KEY_TOSS_CLIENT_KEY)
        defaults.set(baseShippingFee,     forKey: KEY_BASE_SHIPPING_FEE)
        defaults.set(freeShippingThreshold,forKey: KEY_FREE_SHIPPING_THRESHOLD)
    }

    // Android getUserId()
    static func getUserId() -> String {
        return defaults.string(forKey: KEY_ID) ?? ""
    }

    // Android getUserNo()
    static func getUserNo() -> String {
        return defaults.string(forKey: KEY_NO) ?? ""
    }

    // Android getUserPassword()
    static func getUserPassword() -> String {
        return defaults.string(forKey: KEY_PWD) ?? ""
    }

    // Android getMemberCode()
    static func getMemberCode() -> String {
        return defaults.string(forKey: KEY_MEMBER_CODE) ?? ""
    }

    // Android getUserLoginCd()
    static func getUserLoginCd() -> String {
        return defaults.string(forKey: KEY_LOGIN_CD) ?? ""
    }

    static func getUserNm() -> String {
        return defaults.string(forKey: KEY_NM) ?? ""
    }

    // Android getUserSocialId()
    static func getUserSocialId() -> String {
        return defaults.string(forKey: KEY_SOCIAL_ID) ?? ""
    }

    static func getBranchId() -> String {
        return defaults.string(forKey: KEY_BRANCH_ID) ?? ""
    }

    static func getBranchName() -> String {
        return defaults.string(forKey: KEY_BRANCH_NAME) ?? ""
    }

    static func getTossClientKey() -> String {
        return defaults.string(forKey: KEY_TOSS_CLIENT_KEY) ?? ""
    }

    static func getBaseShippingFee() -> Int {
        return defaults.integer(forKey: KEY_BASE_SHIPPING_FEE)
    }

    static func getFreeShippingThreshold() -> Int {
        return defaults.integer(forKey: KEY_FREE_SHIPPING_THRESHOLD)
    }

    // Android isLoggedIn()
    static func isLoggedIn() -> Bool {
        return defaults.bool(forKey: KEY_IS_LOGIN)
    }

    // Android clearLoginInfo()
    static func clearLoginInfo() {
        defaults.removeObject(forKey: KEY_ID)
        defaults.removeObject(forKey: KEY_NO)
        defaults.removeObject(forKey: KEY_NM)
        defaults.removeObject(forKey: KEY_PWD)
        defaults.removeObject(forKey: KEY_MEMBER_CODE)
        defaults.removeObject(forKey: KEY_IS_LOGIN)
        defaults.removeObject(forKey: KEY_LOGIN_CD)
        defaults.removeObject(forKey: KEY_SOCIAL_ID)
        defaults.removeObject(forKey: KEY_BRANCH_ID)
        defaults.removeObject(forKey: KEY_BRANCH_NAME)
        defaults.removeObject(forKey: KEY_TOSS_CLIENT_KEY)
        defaults.removeObject(forKey: KEY_BASE_SHIPPING_FEE)
        defaults.removeObject(forKey: KEY_FREE_SHIPPING_THRESHOLD)
    }
    
    // Convenience helper matching LoginInfo.kt logic
    static func saveLoginInfo(_ login: LoginResponse, email: String? = nil, password: String? = nil) {
           saveLoginInfo(
               email: email ?? login.loginId ?? "",
               loginNo: login.loginIdx ?? "",
               password: password ?? login.loginPwd ?? "",
               memberCode: login.memberCode ?? "",
               loginNm: login.loginNm ?? "",
               loginCd: login.loginCd ?? "",
               loginSocialId: login.loginSocialId ?? "",
               branchId: login.branchInfo?.branchId != nil ? String(login.branchInfo!.branchId!) : nil,
               branchName: login.branchInfo?.branchName,
               tossClientKey: login.branchInfo?.tossClientKey,
               baseShippingFee: login.branchInfo?.baseShippingFee ?? 0,
               freeShippingThreshold: login.branchInfo?.freeShippingThreshold ?? 0
           )
    }
}
