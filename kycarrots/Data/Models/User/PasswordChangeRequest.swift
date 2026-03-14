import Foundation

struct PasswordChangeRequest: Codable {
    let currentPassword: String
    let newPassword: String
    let confirmPassword: String
}
