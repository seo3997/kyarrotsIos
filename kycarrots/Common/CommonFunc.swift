
import Foundation

/// String? → Int64? 안전 변환
/// - nil / "" / 숫자 아님 → nil
func stringToInt64(_ value: String?) -> Int64? {
    guard let s = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !s.isEmpty,
          let v = Int64(s) else {
        return nil
    }
    return v
}
