//
//  ChatMessageResponse.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct ChatMessageResponse: Decodable {
    let id: Int64
    let roomId: String
    let senderId: String
    let message: String
    let createdAt: String
    let time: String
    let isRead: Bool
}
