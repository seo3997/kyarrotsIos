//
//  SocialAuthResponse.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct SocialAuthResponse: Decodable {
    let needOnboarding: Bool
    let needEmail: Bool
    let jwt: String?
    let userId: String?
    let userNo: Int64?
    let provider: String?
    let message: String?
}
