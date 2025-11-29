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

    private static let defaults = UserDefaults.standard

    // Android saveLoginInfo() 동일
    static func saveLoginInfo(
        email: String,
        loginNo: String,
        password: String,
        memberCode: String,
        loginNm: String,
        loginCd: String,
        loginSocialId: String
    ) {
        defaults.set(email,        forKey: KEY_ID)
        defaults.set(loginNo,      forKey: KEY_NO)
        defaults.set(loginNm,      forKey: KEY_NM)
        defaults.set(password,     forKey: KEY_PWD)
        defaults.set(memberCode,   forKey: KEY_MEMBER_CODE)
        defaults.set(true,         forKey: KEY_IS_LOGIN)
        defaults.set(loginCd,      forKey: KEY_LOGIN_CD)
        defaults.set(loginSocialId,forKey: KEY_SOCIAL_ID)
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

    // Android getUserSocialId()
    static func getUserSocialId() -> String {
        return defaults.string(forKey: KEY_SOCIAL_ID) ?? ""
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
    }
}
