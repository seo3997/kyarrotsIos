//
//  OpUserVO.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct OpUserVO: Codable {
    var userNo: Int64
    var userId: String
    var password: String
    var userNm: String
    var cttpcSeCode: String
    var cttpc: String
    var email: String
    var areaCode: String
    var areaCodeNm: String
    var areaSeCodeS: String
    var areaSeCodeSNm: String
    var areaSeCodeD: String
    var userSttusCode: String
    var loginDt: String
    var userAge: String
    var birthDate: String
    var uniqueIdentifier: String
    var deviceId: String
    var duplicateIdentifier: String
    var gender: Int
    var memberCode: String
    var citizenshipType: Int
    var passwordHash: String
    var referrerId: String
    var registerNo: Int
    var registDt: String
    var updusrNo: Int
    var updtDt: String
    var provider: String
    var providerUserId: String
}
