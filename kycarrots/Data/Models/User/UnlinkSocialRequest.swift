//
//  UnlinkSocialRequest.swift
//  kycarrots
//
//  Created by soo on 1/21/26.
//


import Foundation

struct UnlinkSocialRequest: Encodable {
    let provider: String
    let providerUserId: String

    enum CodingKeys: String, CodingKey {
        case provider
        case providerUserId = "providerUserId"
    }
}
