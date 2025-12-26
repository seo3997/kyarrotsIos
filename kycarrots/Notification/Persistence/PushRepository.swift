//
//  PushRepository.swift
//  kycarrots
//
//  Created by soo on 12/26/25.
//


import Foundation
import CoreData

protocol PushRepository {
    func list(userId: String, onlyUnread: Bool, limit: Int, offset: Int) throws -> [PushNotification]
    func markRead(id: UUID) throws
    func markAllRead(userId: String) throws
    func delete(id: UUID) throws
    func countUnread(userId: String) throws -> Int
}

final class CoreDataPushRepository: PushRepository {
    private let ctx: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.ctx = context
    }

    func list(userId: String, onlyUnread: Bool, limit: Int, offset: Int) throws -> [PushNotification] {
        let req = NSFetchRequest<CDPushNotification>(entityName: "CDPushNotification")
        var predicates: [NSPredicate] = [NSPredicate(format: "userId == %@", userId)]
        if onlyUnread { predicates.append(NSPredicate(format: "isRead == NO")) }
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        req.fetchLimit = limit
        req.fetchOffset = offset

        let rows = try ctx.fetch(req)
        return rows.map { $0.toDomain() }
    }

    func markRead(id: UUID) throws {
        let req = NSFetchRequest<CDPushNotification>(entityName: "CDPushNotification")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        if let row = try ctx.fetch(req).first {
            row.isRead = true
            try ctx.save()
        }
    }

    func markAllRead(userId: String) throws {
        let req = NSFetchRequest<CDPushNotification>(entityName: "CDPushNotification")
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "userId == %@", userId),
            NSPredicate(format: "isRead == NO")
        ])
        let rows = try ctx.fetch(req)
        rows.forEach { $0.isRead = true }
        if ctx.hasChanges { try ctx.save() }
    }

    func delete(id: UUID) throws {
        let req = NSFetchRequest<CDPushNotification>(entityName: "CDPushNotification")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        if let row = try ctx.fetch(req).first {
            ctx.delete(row)
            try ctx.save()
        }
    }

    func countUnread(userId: String) throws -> Int {
        let req = NSFetchRequest<NSNumber>(entityName: "CDPushNotification")
        req.resultType = .countResultType
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "userId == %@", userId),
            NSPredicate(format: "isRead == NO")
        ])
        let result = try ctx.fetch(req)
        return result.first?.intValue ?? 0
    }
}

// MARK: - CoreData <-> Domain mapping
extension CDPushNotification {
    func toDomain() -> PushNotification {
        PushNotification(
            id: self.id ?? UUID(),
            userId: self.userId ?? "",
            type: self.type ?? "",
            title: self.title ?? "",
            body: self.body,
            productId: self.productId == 0 ? nil : self.productId,
            sellerId: self.sellerId,
            roomId: self.roomId,
            deeplink: self.deeplink,
            isRead: self.isRead,
            createdAt: self.createdAt ?? Date()
        )
    }
}
