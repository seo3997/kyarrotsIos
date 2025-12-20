//
//  ChatMessage.swift
//  kycarrots
//
//  Created by soo on 12/19/25.
//


import Foundation

struct ChatMessage: Codable {
    let senderId: String
    let message: String
    let roomId: String
    let type: String
    let time: String

    // UI 전용
    var isMe: Bool? = false

    enum CodingKeys: String, CodingKey {
        case senderId, message, roomId, type, time
        // isMe는 인코딩/디코딩 제외
    }
}
