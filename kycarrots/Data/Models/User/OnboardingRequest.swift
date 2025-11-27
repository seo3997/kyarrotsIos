//
//  OnboardingRequest.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct OnboardingRequest: Encodable {
    let nickname: String
    let email: String
    let role: String
    let areaGroup: String?
    let areaMid: String?
    let areaScls: String?
    let marketingPush: Bool
    let marketingEmail: Bool
    let tosAgreed: Bool
    let privacyAgreed: Bool
}

struct OnboardingResponse: Decodable {
    let userId: Int64
    let role: String
}
