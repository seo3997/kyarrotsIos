//
//  PersistenceController.swift
//  kycarrots
//
//  Created by soo on 12/26/25.
//


import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "NotificationModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData load failed: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
