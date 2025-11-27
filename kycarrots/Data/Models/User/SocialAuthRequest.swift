//
//  SocialAuthRequest.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct SocialAuthRequest: Encodable {
    let provider: String
    let providerUserId: String
    let accessToken: String?
    let idToken: String?
    let deviceId: String?
    let appVersion: String?
}
