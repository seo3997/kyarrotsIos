//
//  OpUserVO.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct OpUserVO: Codable {
    var userNo: String?
    var userId: String?
    var password: String?
    var userNm: String?
    var cttpcSeCode: String?
    var cttpc: String?
    var email: String?
    var areaCode: String?
    var areaCodeNm: String?
    var areaSeCodeS: String?
    var areaSeCodeSNm: String?
    var areaSeCodeD: String?
    var userSttusCode: String?
    var loginDt: String?
    var userAge: String?
    var birthDate: String?
    var uniqueIdentifier: String?
    var deviceId: String?
    var duplicateIdentifier: String?
    var gender: Int?
    var memberCode: String?
    var citizenshipType: Int?
    var passwordHash: String?
    var referrerId: String?
    var registerNo: String?
    var registDt: String?
    var updusrNo: String?
    var updtDt: String?
    var provider: String?
    var providerUserId: String?
    var branchId: String?               // 지점 ID
    var joinAppPackage: String?          // 가입 앱 패키지

    enum CodingKeys: String, CodingKey {
        case userNo, userId, password, userNm, cttpcSeCode, cttpc, email
        case areaCode, areaCodeNm, areaSeCodeS, areaSeCodeSNm, areaSeCodeD, userSttusCode
        case loginDt, userAge, birthDate, uniqueIdentifier, deviceId, duplicateIdentifier
        case gender, memberCode, citizenshipType, passwordHash, referrerId, registerNo
        case registDt, updusrNo, updtDt, provider, providerUserId, branchId, joinAppPackage
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userNo = try container.decodeIfPresent(String.self, forKey: .userNo)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        password = try container.decodeIfPresent(String.self, forKey: .password)
        userNm = try container.decodeIfPresent(String.self, forKey: .userNm)
        cttpcSeCode = try container.decodeIfPresent(String.self, forKey: .cttpcSeCode)
        cttpc = try container.decodeIfPresent(String.self, forKey: .cttpc)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        areaCode = try container.decodeIfPresent(String.self, forKey: .areaCode)
        areaCodeNm = try container.decodeIfPresent(String.self, forKey: .areaCodeNm)
        areaSeCodeS = try container.decodeIfPresent(String.self, forKey: .areaSeCodeS)
        areaSeCodeSNm = try container.decodeIfPresent(String.self, forKey: .areaSeCodeSNm)
        areaSeCodeD = try container.decodeIfPresent(String.self, forKey: .areaSeCodeD)
        userSttusCode = try container.decodeIfPresent(String.self, forKey: .userSttusCode)
        loginDt = try container.decodeIfPresent(String.self, forKey: .loginDt)
        userAge = try container.decodeIfPresent(String.self, forKey: .userAge)
        birthDate = try container.decodeIfPresent(String.self, forKey: .birthDate)
        uniqueIdentifier = try container.decodeIfPresent(String.self, forKey: .uniqueIdentifier)
        deviceId = try container.decodeIfPresent(String.self, forKey: .deviceId)
        duplicateIdentifier = try container.decodeIfPresent(String.self, forKey: .duplicateIdentifier)
        
        // Flexible Int/String decoding for gender
        if let g = try? container.decodeIfPresent(Int.self, forKey: .gender) {
            gender = g
        } else if let s = try? container.decodeIfPresent(String.self, forKey: .gender) {
            gender = Int(s)
        }
        
        memberCode = try container.decodeIfPresent(String.self, forKey: .memberCode)
        
        // Flexible Int/String decoding for citizenshipType
        if let c = try? container.decodeIfPresent(Int.self, forKey: .citizenshipType) {
            citizenshipType = c
        } else if let s = try? container.decodeIfPresent(String.self, forKey: .citizenshipType) {
            citizenshipType = Int(s)
        }
        
        passwordHash = try container.decodeIfPresent(String.self, forKey: .passwordHash)
        referrerId = try container.decodeIfPresent(String.self, forKey: .referrerId)
        registerNo = try container.decodeIfPresent(String.self, forKey: .registerNo)
        registDt = try container.decodeIfPresent(String.self, forKey: .registDt)
        updusrNo = try container.decodeIfPresent(String.self, forKey: .updusrNo)
        updtDt = try container.decodeIfPresent(String.self, forKey: .updtDt)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        providerUserId = try container.decodeIfPresent(String.self, forKey: .providerUserId)
        branchId = try container.decodeIfPresent(String.self, forKey: .branchId)
        joinAppPackage = try container.decodeIfPresent(String.self, forKey: .joinAppPackage)
    }
}
