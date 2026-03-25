import Foundation

extension Notification.Name {
    /// 새로운 푸시가 도착하여 로컬 데이터베이스에 저장되었을 때 발생
    static let didReceiveNewPush = Notification.Name("didReceiveNewPush")
}
