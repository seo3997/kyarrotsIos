import Foundation

struct AppVersionResponse: Codable {
    let success: Bool
    let updateType: String? // NONE, OPTIONAL, FORCE
    let latestVersion: String?
    let minVersion: String?
    let updateMsg: String?
    let storeUrl: String?
    let message: String?
}
