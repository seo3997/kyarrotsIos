//
//  EmailSendReq.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct EmailSendReq: Encodable {
    let email: String
}

struct EmailVerifyReq: Encodable {
    let email: String
    let code: String
}

struct EmailVerifyResp: Decodable {
    let verified: Bool
}
