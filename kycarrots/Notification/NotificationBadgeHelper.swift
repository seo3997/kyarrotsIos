//
//  NotificationBadgeHelper.swift
//  kycarrots
//
//  Created by soo on 12/26/25.
//


import Foundation
import CoreData
import UIKit

enum NotificationBadgeHelper {

    /// DB에서 안읽은 개수 조회
    static func fetchUnreadCount(
        userId: String,
        context: NSManagedObjectContext = PersistenceController.shared.container.viewContext
    ) async -> Int {
        guard !userId.isEmpty else { return 0 }

        return await withCheckedContinuation { cont in
            context.perform {
                let req = NSFetchRequest<NSNumber>(entityName: "CDPushNotification")
                req.resultType = .countResultType
                req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "userId == %@", userId),
                    NSPredicate(format: "isRead == NO")
                ])

                do {
                    let count = try context.fetch(req).first?.intValue ?? 0
                    cont.resume(returning: count)
                } catch {
                    print("❌ unread count 조회 실패:", error)
                    cont.resume(returning: 0)
                }
            }
        }
    }

    /// UILabel(커스텀 뱃지)에 숫자 적용
    @MainActor
    static func applyBadgeLabel(_ badgeLabel: UILabel?, count: Int) {
        guard let badgeLabel else { return }

        if count <= 0 {
            badgeLabel.isHidden = true
            badgeLabel.text = nil
        } else {
            badgeLabel.isHidden = false
            badgeLabel.text = count > 99 ? "99+" : "\(count)"
        }
    }

    /// (옵션) App 아이콘 뱃지까지 같이 반영하고 싶을 때
    @MainActor
    static func applyAppIconBadge(_ count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = max(0, count)
    }
}
