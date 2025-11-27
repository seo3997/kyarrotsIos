//
//  ChatRoomResponse.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct ChatRoomResponse: Decodable {
    let id: Int64
    let roomId: String
    let buyerId: String
    let sellerId: String
    let productId: String
    let createdAt: String
}
