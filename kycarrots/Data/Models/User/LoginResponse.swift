//
//  LoginResponse.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct LoginResponse: Decodable {
    let resultCode: Int
    let token: String?
    let loginIdx: String?
    let loginSi: String?
    let loginGu: String?
    let loginSex: String?
    let loginAge: String?
    let loginNm: String?
    let memberCode: String?
    let loginId: String?
    let loginCd: String
    let loginSocialId: String
    let loginPwd: String

    enum CodingKeys: String, CodingKey {
        case resultCode      = "resultCode"
        case token           = "token"
        case loginIdx        = "login_idx"
        case loginSi         = "login_si"
        case loginGu         = "login_gu"
        case loginSex        = "login_sex"
        case loginAge        = "login_age"
        case loginNm         = "login_nm"
        case memberCode      = "member_code"
        case loginId         = "login_id"
        case loginCd         = "login_cd"
        case loginSocialId   = "login_social_id"
        case loginPwd        = "login_pwd"
    }
}
