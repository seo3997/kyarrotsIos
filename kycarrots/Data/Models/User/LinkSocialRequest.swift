//
//  LinkSocialRequest.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct LinkSocialRequest: Encodable {
    let userId: String
    let userNo: String
    let provider: String?
    let providerUserId: String?
}
