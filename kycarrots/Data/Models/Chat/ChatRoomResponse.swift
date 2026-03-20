//
//  ChatRoomResponse.swift
//  kycarrots
//
//  Created by soohyun on 11/27/25.
//


import Foundation

struct ChatRoomResponse: Codable {
    let id: Int64
    let roomId: String
    let buyerId: String
    let branchId: String
    let productId: Int64
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case roomId
        case buyerId
        case branchId
        case productId
        case createdAt = "created_at"
    }
}
