//
//  PushTokenVo.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct PushTokenVo: Encodable {
    let userNo: String
    let userId: String
    let pushToken: String
    let deviceType: String
}
