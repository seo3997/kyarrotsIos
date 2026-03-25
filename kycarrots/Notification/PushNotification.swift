//
//  PushNotification.swift
//  kycarrots
//
//  Created by soo on 12/26/25.
//


import Foundation

struct PushNotification: Hashable {
    let id: UUID

    let userId: String
    let type: String
    let title: String
    let body: String?
    let targetId: String?
    let deeplink: String?

    var isRead: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        userId: String,
        type: String,
        title: String,
        body: String?,
        targetId: String?,
        deeplink: String?,
        isRead: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.body = body
        self.targetId = targetId
        self.deeplink = deeplink
        self.isRead = isRead
        self.createdAt = createdAt
    }
}
